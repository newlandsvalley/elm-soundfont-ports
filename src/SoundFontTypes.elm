module SoundFontTypes exposing (..)

type alias AudioNode = 
  {
  }

{-| Audio Context -}
type alias AudioContext =
  {
    currentTime : Float
  , destination : AudioNode
  , sampleRate : Int
  } 

{-| Midi Note -}
type alias MidiNote =
  { id  : Int
  , timeOffset : Float
  , gain : Float
  }

