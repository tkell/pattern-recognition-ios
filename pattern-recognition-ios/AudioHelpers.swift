//
//  AudioHelpers.swift
//  pattern-recognition-ios
//
//  Created by Thor Kell on 1/21/18.
//  Copyright © 2018 Thor Kell. All rights reserved.
//

import AudioKit

func createOsc(shape: String, a: Double, d: Double, s: Double, r: Double) ->  AKOscillatorBank {
    var table = AKTable(.sine)
    if shape == "triangle" {
        table = AKTable(.triangle)
    }
    if shape == "square" {
        table = AKTable(.square)
    }
    
    return AKOscillatorBank(waveform: table,
                            attackDuration: a,
                            decayDuration: d,
                            sustainLevel: s,
                            releaseDuration: r
    )
}

func createAudioPath(osc: AKOscillatorBank, f: Double, res: Double, t: Double, fb: Double, mix: Double) -> AKNode{
    let filter = AKLowPassFilter(osc, cutoffFrequency: 6500.0, resonance: 0.1)
    let delay = AKDelay(filter, time: 0.166, feedback: 0.35, dryWetMix: 0.1)
    return delay
}

func playNote(midi: AKMIDI, oscs: Array<AKOscillatorBank>, note: MIDINoteNumber, vel: Int, freq: Double) -> Void {
    midi.sendEvent(AKMIDIEvent(noteOn: MIDINoteNumber(note), velocity: MIDIVelocity(vel), channel: 1))
    oscs.forEach { (osc) in
        osc.play(noteNumber: MIDINoteNumber(note), velocity: MIDIVelocity(vel), frequency: freq)
    }
}

func stopNote(midi: AKMIDI, oscs: Array<AKOscillatorBank>, note: MIDINoteNumber) -> Void {
    midi.sendEvent(AKMIDIEvent(noteOff: MIDINoteNumber(note), velocity: MIDIVelocity(0), channel: 1))
    oscs.forEach { (osc) in
        osc.stop(noteNumber: MIDINoteNumber(note))
    }
}