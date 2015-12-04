//
//  Song.swift
//  PitchPerfect
//
//  Created by iGuest on 11/24/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

import Foundation

class Song {
    var title : String
    var data : String
    
    internal private(set) var currentNote: Note?
    
    var notes: [Note]
    var currentNoteIndex: Int = 0
    private var shouldStop: Bool = false
    
    // MARK: Init methods
    
    init(title: String, data: String) {
        self.title = title
        self.data = data
        self.notes = Array()
    }
    
    init () {
        self.title = ""
        self.data = ""
        self.notes = []
    }
    
    /*
     * Parse MIDI file into Note array
     * http://ericjknapp.com/blog/2014/03/30/midi-files-and-tracks/
     */
    init(withMIDIFileURL: NSURL) {
        self.title = ""
        self.data = ""
        self.notes = Array()
        
        var sequence: MusicSequence = nil
        NewMusicSequence(&sequence);
        
        let midiFileCFUrl = withMIDIFileURL as CFURLRef
        
        MusicSequenceFileLoad(
            sequence,
            midiFileCFUrl,
            MusicSequenceFileTypeID.MIDIType,
            MusicSequenceLoadFlags.SMF_PreserveTracks
        );
        
        self.initMIDICommon(sequence)
    }
    
    init(withBase64DataString: String, title: String) {
        self.title = title
        self.data = ""
        self.notes = Array()
        
        var sequence: MusicSequence = nil
        NewMusicSequence(&sequence);
        
        let decodedMIDIData = NSData(base64EncodedString: withBase64DataString, options: NSDataBase64DecodingOptions(rawValue: 0))
        if decodedMIDIData == nil {
            print("MIDI data for song \(title) was nil")
            return
        }
        
        MusicSequenceFileLoadData(
            sequence,
            decodedMIDIData!,
            MusicSequenceFileTypeID.MIDIType,
            MusicSequenceLoadFlags.SMF_PreserveTracks
        );
        
        self.initMIDICommon(sequence)
    }
    
    func initMIDICommon(sequence: MusicSequence) {
        let track: MusicTrack = self.getTrack(sequence, index: 0)
        self.importMIDITrack(track)
        
        if self.hasNextNote() {
            self.currentNote = self.notes[0]
        }
    }
    
    // MARK: Playing notes
    
    func restart() {
        self.currentNoteIndex == 0
        self.currentNote = self.notes[0]
    }
    
    /**
    * Advances to the next note.
    *
    * @returns TRUE if the song has another note, otherwise FALSE
    */
    func hasNextNote() -> Bool {
        return self.notes.count > self.currentNoteIndex + 1
    }
    
    func moveToNextNote() {
        self.currentNoteIndex++
        self.currentNote = self.notes[self.currentNoteIndex]
    }
    
    func playCurrentNote() {
        self.currentNote!.playForDuration()
    }
    
    func play() {
        self.shouldStop = false
        self.playByNoteAtIndex(0)
    }
    
    func stopPlaying() {
        self.shouldStop = true
    }
    
    private func playByNoteAtIndex(index: Int) {
        if index == self.notes.count || self.shouldStop {
            return
        }
        
        let note = self.notes[index]
        note.playForDuration()
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(note.duration * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            note.stop()
            self.playByNoteAtIndex(index+1)
        }
    }
    
    
    // MARK: MIDI processing
    
    /**
     * Thanks to:
     * https://github.com/genedelisa/MusicSequence/blob/master/MusicSequence/MIDIFrobs.swift
     * and
     * http://ericjknapp.com/blog/2014/04/05/midi-events/
     */
    func importMIDITrack(track: MusicTrack)
    {
        var iterator: MusicEventIterator = nil
        NewMusicEventIterator(track, &iterator)
        
        let hasNext: UnsafeMutablePointer<DarwinBoolean> = UnsafeMutablePointer.alloc(Int(true))
        MusicEventIteratorHasCurrentEvent(iterator, hasNext)
        var eventType:MusicEventType = 0
        var eventTimeStamp:MusicTimeStamp = -1
        var previousEventTimeStamp:MusicTimeStamp = -1
        var eventData: UnsafePointer<()> = nil
        var eventDataSize:UInt32 = 0
        
        MusicEventIteratorHasCurrentEvent(iterator, hasNext);
        while (hasNext.memory.boolValue)
        {
            MusicEventIteratorGetEventInfo(iterator, &eventTimeStamp, &eventType, &eventData, &eventDataSize);
            
            if  eventType == kMusicEventType_MIDINoteMessage
            {
                let data = UnsafePointer<MIDINoteMessage>(eventData)
                let midiNoteMessage = data.memory
                // print("Note message \(midiNoteMessage.note), vel \(midiNoteMessage.velocity) dur \(midiNoteMessage.duration) at time \(eventTimeStamp)")
                
                let name = Constants.MIDI_NOTE_NUMBER_TO_NAME_STRING[Int(midiNoteMessage.note)]
                let duration = Double(midiNoteMessage.duration)
                if name != nil {
                    let note = Note(noteName: name!, duration: duration, velocity: midiNoteMessage.velocity)
                    
                    // the note we just read is in harmony (played at the same time) as the last note
                    if previousEventTimeStamp == eventTimeStamp {
                        // the melody of a song is usually the highest note, so if two notes are
                        // played harmonically, we will just choose the highest note by default
                        let previousNote = self.notes[self.notes.count-1]
                        if previousNote.frequency < note.frequency {
                            self.notes[self.notes.count-1] = note
                        }
                    } else {
                        // otherwise just add to the note array
                        self.notes.append(note)
                    }
                    
                    previousEventTimeStamp = eventTimeStamp
                    // print(note)
                } else {
                    print("Can not find note")
                }
            }
            
            MusicEventIteratorNextEvent(iterator);
            MusicEventIteratorHasCurrentEvent(iterator, hasNext);
        }
    }
    
    /**
     * https://github.com/genedelisa/MusicSequence/blob/master/MusicSequence/MIDIFrobs.swift
     */
    func getTrackCount(sequence: MusicSequence) -> UInt32 {
        var trackCount:UInt32 = 0
        MusicSequenceGetTrackCount(sequence, &trackCount)
        return trackCount
    }
    
    /**
     * https://github.com/genedelisa/MusicSequence/blob/master/MusicSequence/MIDIFrobs.swift
     */
    func getTrack(sequence: MusicSequence, index: UInt32) -> MusicTrack {
        var track: MusicTrack = nil
        MusicSequenceGetIndTrack(sequence, index, &track)
        return track
    }
    
    /*
     * Not really sure what this does, but may be useful later...
     * http://ericjknapp.com/blog/2014/03/30/midi-files-and-tracks/
     */
    func parseTempoTrack(sequence: MusicSequence) {
        var tempoTrack: MusicTrack  = nil
        MusicSequenceGetTempoTrack(sequence, &tempoTrack);
        
        var iterator: MusicEventIterator  = nil
        NewMusicEventIterator(tempoTrack, &iterator);
        
        let hasNext: UnsafeMutablePointer<DarwinBoolean> = UnsafeMutablePointer.alloc(Int(true))
        var timestamp: MusicTimeStamp  = 0;
        var eventType: MusicEventType  = 0;
        var eventDataSize: UInt32  = 0;
        var eventData: UnsafePointer<()> = nil
        
        MusicEventIteratorHasCurrentEvent(iterator, hasNext);
        while (hasNext.memory.boolValue)
        {
            MusicEventIteratorGetEventInfo(iterator,
                &timestamp,
                &eventType,
                &eventData,
                &eventDataSize);
            
            // Process each event here
            print("Event found! type: \(eventType.description)");
            
            // go to next event
            MusicEventIteratorNextEvent(iterator);
            MusicEventIteratorHasCurrentEvent(iterator, hasNext);
        }       
    }
}