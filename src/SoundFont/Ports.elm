port module SoundFont.Ports exposing (..)


import SoundFont.Types exposing (..)

-- outgoing ports (for commands to javascript)

port initialiseAudioContext : () -> Cmd msg

port requestIsOggEnabled : () -> Cmd msg

port requestLoadFonts : String -> Cmd msg

port requestPlayNote : MidiNote -> Cmd msg

port requestPlayNoteSequence : MidiNotes -> Cmd msg


-- incoming ports (for subscriptions from javascript)

port getAudioContext : (AudioContext -> msg) -> Sub msg

port oggEnabled : (Bool -> msg) -> Sub msg

port fontsLoaded : (Bool -> msg) -> Sub msg


