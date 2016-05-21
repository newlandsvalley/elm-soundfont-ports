module SoundFont.Msg exposing (..)

import SoundFont.Types exposing (..)

type Msg =
    InitialiseAudioContext
  | ResponseAudioContext AudioContext
  | RequestOggEnabled
  | ResponseOggEnabled Bool
  | RequestLoadFonts String
  | ResponseFontsLoaded Bool
  | RequestPlayNote MidiNote
  | RequestPlayNoteSequence MidiNotes
  | NoOp



