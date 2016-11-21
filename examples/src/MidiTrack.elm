module MidiTrack
    exposing
        ( MidiTrack
        , fromRecording
        )

{-| conversion of a MIDI recording to a performance of just Track 0

# Definition

# Data Types
@docs MidiTrack

# Functions
@docs fromRecording

-}

import MidiTypes exposing (..)
import Array exposing (Array, fromList)
import Maybe exposing (withDefault)
import Tuple exposing (first, second)
import Debug exposing (..)


{-| Midi Track
-}
type alias MidiTrack =
    { ticksPerBeat : Int
    , messages : Array MidiMessage
    }


{-| translate a MIDI recording of track 0 to a MidiTrack0 description
-}
fromRecording : MidiRecording -> MidiTrack
fromRecording mr =
    let
        header =
            first mr

        tracks =
            second mr

        track0 =
            List.head (List.reverse tracks)
                |> withDefault []
                |> Array.fromList
    in
        { ticksPerBeat = header.ticksPerBeat, messages = track0 }
