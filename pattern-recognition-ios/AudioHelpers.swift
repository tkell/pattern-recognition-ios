//
//  AudioHelpers.swift
//  pattern-recognition-ios
//
//  Created by Thor Kell on 1/21/18.
//  Copyright © 2018 Thor Kell. All rights reserved.
//

import AudioKit

class PatternSynth {
    var osc1: AKOscillatorBank
    var osc2: AKOscillatorBank
    var oscs: Array<AKOscillatorBank> = []
    var mixer: AKMixer

    required init() {
        self.osc1 = createOsc(shape: "square", a: 0.125, d: 0.35, s: 0.05, r: 0.15)
        self.osc2 = createOsc(shape: "triangle", a: 0.1, d: 0.4, s: 0.1, r: 0.25)
        self.oscs.append(osc1)
        self.oscs.append(osc2)

        self.mixer = AKMixer(createAudioPath(osc: self.osc1, f: 6500, res: 0.1, t: 0.166, fb: 0.35, mix: 0.1),
                             createAudioPath(osc: self.osc2, f: 8000, res: 0.1, t: 0.15, fb: 0.4, mix: 0.2)
            )
    }
}

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
    let filter = AKLowPassFilter(osc, cutoffFrequency: 4750.0, resonance: 0.1)
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
