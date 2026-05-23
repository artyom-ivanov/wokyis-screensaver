import Foundation
import QuartzCore

struct GoLConfig {
    var cols: Int = 200
    var stepsPerSec: Double = 20
    var density: Double = 0.15
    var trailDecay: UInt8 = 9
    var preEvolveSteps: Int = 12
    var stuckThreshold: Int = 32
    var stuckTolerance: Int = 2
    var hardCapGens: Int = 460
    var wipeDuration: CFTimeInterval = 1.8
    var wipeBandFraction: Float = 0.18  // of viewport width
}

struct GoLState {
    let cols: Int
    let rows: Int
    var state: [UInt8]
    var trail: [UInt8]
    var trailColor: [UInt8]

    private var nextState: [UInt8]

    init(cols: Int, rows: Int) {
        self.cols = cols
        self.rows = rows
        let count = cols * rows
        self.state = [UInt8](repeating: 0, count: count)
        self.nextState = [UInt8](repeating: 0, count: count)
        self.trail = [UInt8](repeating: 0, count: count)
        self.trailColor = [UInt8](repeating: 0, count: count)
    }

    var population: Int {
        var p = 0
        for s in state where s != 0 { p += 1 }
        return p
    }

    mutating func seed(density: Double) {
        for i in 0..<state.count {
            if Double.random(in: 0..<1) < density {
                state[i] = Bool.random() ? 1 : 2
            } else {
                state[i] = 0
            }
        }
        for i in 0..<trail.count {
            trail[i] = 0
            trailColor[i] = 0
        }
    }

    mutating func step(trailDecay: UInt8) {
        let c = cols
        let r = rows

        state.withUnsafeBufferPointer { src in
            nextState.withUnsafeMutableBufferPointer { dst in
                for y in 0..<r {
                    let yUp   = (y == 0)     ? r - 1 : y - 1
                    let yDown = (y == r - 1) ? 0     : y + 1
                    let rowUp   = yUp * c
                    let rowMid  = y * c
                    let rowDown = yDown * c
                    for x in 0..<c {
                        let xL = (x == 0)     ? c - 1 : x - 1
                        let xR = (x == c - 1) ? 0     : x + 1

                        let n0 = src[rowUp + xL]
                        let n1 = src[rowUp + x]
                        let n2 = src[rowUp + xR]
                        let n3 = src[rowMid + xL]
                        let n4 = src[rowMid + xR]
                        let n5 = src[rowDown + xL]
                        let n6 = src[rowDown + x]
                        let n7 = src[rowDown + xR]

                        var nA = 0, nB = 0
                        for n in [n0, n1, n2, n3, n4, n5, n6, n7] {
                            if n == 1 { nA += 1 }
                            else if n == 2 { nB += 1 }
                        }
                        let nTotal = nA + nB
                        let current = src[rowMid + x]
                        let nextVal: UInt8
                        if current != 0 {
                            nextVal = (nTotal == 2 || nTotal == 3) ? current : 0
                        } else {
                            nextVal = (nTotal == 3) ? (nA > nB ? 1 : 2) : 0
                        }
                        dst[rowMid + x] = nextVal
                    }
                }
            }
        }

        swap(&state, &nextState)

        for i in 0..<state.count {
            if state[i] != 0 {
                trail[i] = 255
                trailColor[i] = state[i]
            } else if trail[i] > 0 {
                trail[i] = trail[i] >= trailDecay ? trail[i] - trailDecay : 0
            }
        }
    }
}

final class GameOfLifeEngine {
    let config: GoLConfig
    let cols: Int
    let rows: Int

    private(set) var current: GoLState
    private(set) var old: GoLState?

    private(set) var wipeStart: CFTimeInterval?
    private var generationCount: Int = 0
    private var stuckCount: Int = 0
    private var prevPopulation: Int = 0

    init(cols: Int, rows: Int, config: GoLConfig = GoLConfig()) {
        self.cols = cols
        self.rows = rows
        self.config = config
        self.current = GoLState(cols: cols, rows: rows)
        seedCurrent()
    }

    /// 0 if not wiping, otherwise 0...1 progress.
    var wipeProgress: Float {
        guard let start = wipeStart else { return -1 }
        let p = (CACurrentMediaTime() - start) / config.wipeDuration
        return Float(min(max(p, 0), 1))
    }

    func step() {
        current.step(trailDecay: config.trailDecay)
        if old != nil {
            old!.step(trailDecay: config.trailDecay)
        }

        if let start = wipeStart, CACurrentMediaTime() - start >= config.wipeDuration {
            old = nil
            wipeStart = nil
        }

        if wipeStart == nil {
            generationCount += 1
            let pop = current.population
            if abs(pop - prevPopulation) <= config.stuckTolerance {
                stuckCount += 1
            } else {
                stuckCount = 0
            }
            prevPopulation = pop

            if pop == 0 || stuckCount >= config.stuckThreshold || generationCount >= config.hardCapGens {
                startWipe()
            }
        }
    }

    private func seedCurrent() {
        current.seed(density: config.density)
        for _ in 0..<config.preEvolveSteps {
            current.step(trailDecay: config.trailDecay)
        }
        generationCount = 0
        stuckCount = 0
        prevPopulation = current.population
    }

    private func startWipe() {
        old = current
        var fresh = GoLState(cols: cols, rows: rows)
        fresh.seed(density: config.density)
        for _ in 0..<config.preEvolveSteps {
            fresh.step(trailDecay: config.trailDecay)
        }
        current = fresh
        wipeStart = CACurrentMediaTime()
        generationCount = 0
        stuckCount = 0
        prevPopulation = current.population
    }
}
