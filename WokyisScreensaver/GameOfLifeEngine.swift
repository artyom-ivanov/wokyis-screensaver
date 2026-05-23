import Foundation

struct GoLConfig {
    var cols: Int = 200
    var stepsPerSec: Double = 20
    var density: Double = 0.15
    var trailDecay: UInt8 = 9
    var preEvolveSteps: Int = 6
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
                trail.withUnsafeMutableBufferPointer { trailBuf in
                    trailColor.withUnsafeMutableBufferPointer { trailColBuf in
                        for y in 0..<r {
                            let yUp   = (y == 0)     ? r - 1 : y - 1
                            let yDown = (y == r - 1) ? 0     : y + 1
                            let rowUp   = yUp * c
                            let rowMid  = y * c
                            let rowDown = yDown * c
                            for x in 0..<c {
                                let xL = (x == 0)     ? c - 1 : x - 1
                                let xR = (x == c - 1) ? 0     : x + 1
                                let idx = rowMid + x

                                var nA = 0, nB = 0
                                @inline(__always) func tally(_ n: UInt8) {
                                    if n == 1 { nA &+= 1 } else if n == 2 { nB &+= 1 }
                                }
                                tally(src[rowUp + xL])
                                tally(src[rowUp + x])
                                tally(src[rowUp + xR])
                                tally(src[rowMid + xL])
                                tally(src[rowMid + xR])
                                tally(src[rowDown + xL])
                                tally(src[rowDown + x])
                                tally(src[rowDown + xR])
                                let nTotal = nA + nB
                                let current = src[idx]
                                let nextVal: UInt8
                                if current != 0 {
                                    nextVal = (nTotal == 2 || nTotal == 3) ? current : 0
                                } else {
                                    nextVal = (nTotal == 3) ? (nA > nB ? 1 : 2) : 0
                                }
                                dst[idx] = nextVal

                                // Trail update fused into the same pass — saves one
                                // full sweep over 22600 cells per generation.
                                if nextVal != 0 {
                                    trailBuf[idx] = 255
                                    trailColBuf[idx] = nextVal
                                } else {
                                    let t = trailBuf[idx]
                                    if t > 0 {
                                        trailBuf[idx] = t >= trailDecay ? t - trailDecay : 0
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        swap(&state, &nextState)
    }
}

final class GameOfLifeEngine {
    let config: GoLConfig
    let cols: Int
    let rows: Int

    private(set) var current: GoLState

    init(cols: Int, rows: Int, config: GoLConfig = GoLConfig()) {
        self.cols = cols
        self.rows = rows
        self.config = config
        self.current = GoLState(cols: cols, rows: rows)
        reseed()
    }

    func step() {
        current.step(trailDecay: config.trailDecay)
    }

    func reseed() {
        current.seed(density: config.density)
        for _ in 0..<config.preEvolveSteps {
            current.step(trailDecay: config.trailDecay)
        }
    }
}
