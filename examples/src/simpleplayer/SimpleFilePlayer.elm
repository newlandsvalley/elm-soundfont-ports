module SimpleFilePlayer exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)
import Html.Attributes exposing (..)
import Http exposing (..)
import Task exposing (..)
import List exposing (..)
import Maybe exposing (..)
import String exposing (..)
import Result exposing (Result)
import Html.App as Html
import CoMidi exposing (normalise, parse, translateRunningStatus)
import MidiTypes exposing (MidiRecording)
import MidiPerformance exposing (..)
import SoundFont.Ports exposing (..)
import SoundFont.Types exposing (..)

main =
  Html.program
    { init = (init, Cmd.none), update = update, view = view, subscriptions = subscriptions }

-- MODEL

type alias Sounds = List MidiNote

type alias Model =
    { audioContext : Maybe AudioContext
    , fontsLoaded : Bool
    , performance : Result String MidiPerformance
    }

init : Model
init = 
  Model Nothing False (Err "not started")

-- MESSAGES

type Msg =
    InitialiseAudioContext
  | InitialisedAudioContext AudioContext
  | RequestLoadFonts String
  | FontsLoaded Bool
  | LoadMidi String
  | Midi (Result String MidiPerformance )
  | Play
  | NoOp

-- UPDATE

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    InitialiseAudioContext ->
      ( model
      , initialiseAudioContext ()
      )
    InitialisedAudioContext context ->
      ( { model | audioContext = Just context }
      , Cmd.none
      )
    RequestLoadFonts dir ->
      ( model
      , requestLoadFonts dir
      )
    FontsLoaded loaded ->
      ( { model | fontsLoaded = loaded }
      , Cmd.none
      )
    LoadMidi name -> 
     ( model
     , loadMidi name
     )
    Midi perfres -> 
      ( { model | performance = perfres }
      , Cmd.none
      )
    Play ->
     let
       notes = makeMIDINotes model.performance
     in
       ( model
       , requestPlayNoteSequence notes 
       )
    NoOp ->
      ( model, Cmd.none )

-- VIEW

viewPerformanceResult : Result String MidiPerformance -> String
viewPerformanceResult mr = case mr of
      Ok res -> "OK: " ++ (toString res)
      Err errs -> "Fail: " ++ (toString errs)

viewPlayButton: Model -> Html Msg
viewPlayButton model =
  case (model.fontsLoaded, model.performance) of
    (True, Ok _) ->
      button
        [
          onClick Play
        , btnStyle
        ] [ text "play" ]
    _ ->
      div [] []

view : Model -> Html Msg
view model =
  div []
    [ 
      button 
        [ 
          onClick (RequestLoadFonts "soundfonts")
        , btnStyle 
        ] [ text "load fonts" ]
    , button 
        [ 
          onClick (LoadMidi "midi/lillasystern.midi")
        , btnStyle
        ] [ text "load file" ]
    , div [  ] [ text 
                 ("fonts loaded: " ++ (toString model.fontsLoaded)) 
               ]
    , div [  ] [ text 
                 (" parsed midi result: " ++ (viewPerformanceResult model.performance)) 
               ]
    , viewPlayButton model
    ]

btnStyle : Attribute msg
btnStyle =
  style
    [
      ("font-size", "1em")
    , ("text-align", "center")
    ]

-- SUBSCRIPTIONS
audioContextSub : Sub Msg
audioContextSub =
  getAudioContext InitialisedAudioContext

fontsLoadedSub : Sub Msg
fontsLoadedSub  =
  fontsLoaded FontsLoaded

subscriptions : Model -> Sub Msg
subscriptions model
  = Sub.batch [audioContextSub, fontsLoadedSub]

-- THE ACTUAL WORK
  
{- load a MIDI file -}
loadMidi : String -> Cmd Msg
loadMidi url = 
      let settings =  { defaultSettings | desiredResponseType  = Just "text/plain; charset=x-user-defined" }   
        in
          Http.send settings
                          { verb = "GET"
                          , headers = []
                          , url = url
                          , body = empty
                          } 
          |> Task.toResult
          |> Task.map extractResponse
          |> Task.map parseLoadedFile
          |> Task.perform (\_ -> NoOp) Midi 


{- make the next MIDI note -}
makeMIDINote : Int -> NoteEvent -> (MidiNotes, Float) -> (MidiNotes, Float)
makeMIDINote ticksPerBeat ne acc = 
  let 
    (ticks, notable) = ne
    notes = fst acc         
    microsecondsPerBeat = snd acc
  in
    case notable of
     -- shouldn't happen - just satisfies ADT
     NoNote ->        
       acc
     -- we've hit a Note
     Note pitch velocity ->
       let 
         elapsedTime = 
           microsecondsPerBeat * Basics.toFloat ticks / (Basics.toFloat ticksPerBeat  * 1000000)
         maxVelocity = 0x7F
         gain =
           Basics.toFloat velocity / maxVelocity
         midiNote = MidiNote pitch elapsedTime gain
       in
         (midiNote :: notes,  microsecondsPerBeat)
     -- we've hit a new Tempo indicator to replace the last one
     MicrosecondsPerBeat ms ->
       (fst acc, Basics.toFloat ms)


{- make the MIDI notes - if we have a performance result from parsing the midi file, convert
   the performance into a list of MidiNote
-}
makeMIDINotes :  Result String MidiPerformance -> MidiNotes
makeMIDINotes perfResult = 
     case perfResult of
       Ok perf ->
        let
          fn = makeMIDINote perf.ticksPerBeat
          defaultPace =  Basics.toFloat 500000
          line = perf.lines
                 |> List.head
                 |> withDefault []
        in
          List.foldl fn ([], defaultPace) line
          |> fst 
          |> List.reverse 
       Err err ->
         []

{- extract the true response, concentrating on 200 statuses - assume other statuses are in error
   (usually 404 not found)
-}
extractResponse : Result RawError Response -> Result String Value
extractResponse result = case result of
    Ok response -> case response.status of
        200 -> Ok response.value
        _ -> Err (toString (response.status) ++ ": " ++ response.statusText)
    Err e -> Err "unexpected http error"

{- cast a String to an Int -}
toInt : String -> Int
toInt = String.toInt >> Result.toMaybe >> Maybe.withDefault 0

toPerformance : Result String MidiRecording -> Result String MidiPerformance
toPerformance r = Result.map fromRecording r

parseLoadedFile : Result String Value -> Result String MidiPerformance
parseLoadedFile r = case r of
  Ok text -> case text of
    Text s -> s |> normalise |> parse |> translateRunningStatus |> toPerformance
    Blob b -> Err "Blob unsupported"
  Err e -> Err e





