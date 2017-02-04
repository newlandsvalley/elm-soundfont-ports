module SimpleFilePlayer exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick, on, onInput, targetValue)
import Html.Attributes exposing (..)
import Http exposing (..)
import Task exposing (..)
import List exposing (..)
import Maybe exposing (..)
import Tuple exposing (first, second)
import String exposing (..)
import Result exposing (Result)
import Json.Decode as Json exposing (..)
import CoMidi exposing (normalise, parse, translateRunningStatus)
import MidiTypes exposing (MidiRecording)
import MidiPerformance exposing (..)
import SoundFont.Ports exposing (..)
import SoundFont.Types exposing (..)
import BinaryFileIO.Ports exposing (..)


main =
    Html.program
        { init = ( init, Cmd.none ), update = update, view = view, subscriptions = subscriptions }



-- MODEL


type alias Sounds =
    List MidiNote


type alias Model =
    { audioContext : Maybe AudioContext
    , fontsLoaded : Bool
    , performance : Result String MidiPerformance
    }


init : Model
init =
    Model Nothing False (Err "not started")



-- MESSAGES


type Msg
    = InitialiseAudioContext
    | InitialisedAudioContext AudioContext
    | RequestLoadPianoFonts String
    | FontsLoaded Bool
    | RequestFileUpload
    | FileLoaded (Maybe Filespec)
    | Play
    | NoOp



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
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

        RequestLoadPianoFonts dir ->
            ( model
            , requestLoadPianoFonts dir
            )

        FontsLoaded loaded ->
            ( { model | fontsLoaded = loaded }
            , Cmd.none
            )

        RequestFileUpload ->
            ( model, requestLoadFile () )

        FileLoaded maybef ->
            case maybef of
                Just f ->
                    ( { model
                        | performance =
                            normalise f.contents
                                |> parse
                                |> translateRunningStatus
                                |> toPerformance
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        Play ->
            let
                notes =
                    makeMIDINotes model.performance
            in
                ( model
                , requestPlayNoteSequence notes
                )

        NoOp ->
            ( model, Cmd.none )



-- VIEW


viewPerformanceResult : Result String MidiPerformance -> String
viewPerformanceResult mr =
    case mr of
        Ok res ->
            "OK: " ++ (toString res)

        Err errs ->
            "Fail: " ++ (toString errs)


viewPlayButton : Model -> Html Msg
viewPlayButton model =
    case ( model.fontsLoaded, model.performance ) of
        ( True, Ok _ ) ->
            button
                [ onClick Play
                , btnStyle
                ]
                [ text "play" ]

        _ ->
            div [] []


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "MIDI file player" ]
        , button
            [ onClick (RequestLoadPianoFonts "soundfonts")
            , btnStyle
            ]
            [ text "load fonts" ]
        , input
            [ type_ "file"
            , id "fileinput"
            , accept ".midi"
            , on "change" (Json.succeed RequestFileUpload)
            ]
            []
        , div []
            [ text
                ("fonts loaded: " ++ (toString model.fontsLoaded))
            ]
        , div []
            [ text
                (" parsed midi result: " ++ (viewPerformanceResult model.performance))
            ]
        , viewPlayButton model
        ]


btnStyle : Attribute msg
btnStyle =
    style
        [ ( "font-size", "1em" )
        , ( "text-align", "center" )
        ]



-- SUBSCRIPTIONS


audioContextSub : Sub Msg
audioContextSub =
    getAudioContext InitialisedAudioContext


fontsLoadedSub : Sub Msg
fontsLoadedSub =
    fontsLoaded FontsLoaded


fileLoadedSub : Sub Msg
fileLoadedSub =
    fileLoaded FileLoaded


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ audioContextSub, fontsLoadedSub, fileLoadedSub ]



-- THE ACTUAL WORK
{- make the next MIDI note -}


makeMIDINote : Int -> NoteEvent -> ( MidiNotes, Float ) -> ( MidiNotes, Float )
makeMIDINote ticksPerBeat ne acc =
    let
        ( ticks, notable ) =
            ne

        notes =
            first acc

        microsecondsPerBeat =
            second acc
    in
        case notable of
            -- shouldn't happen - just satisfies ADT
            NoNote ->
                acc

            -- we've hit a Note
            Note pitch velocity ->
                let
                    elapsedTime =
                        microsecondsPerBeat * Basics.toFloat ticks / (Basics.toFloat ticksPerBeat * 1000000)

                    maxVelocity =
                        0x7F

                    gain =
                        Basics.toFloat velocity / maxVelocity

                    midiNote =
                        MidiNote pitch elapsedTime gain
                in
                    ( midiNote :: notes, microsecondsPerBeat )

            -- we've hit a new Tempo indicator to replace the last one
            MicrosecondsPerBeat ms ->
                ( first acc, Basics.toFloat ms )



{- make the MIDI notes - if we have a performance result from parsing the midi file, convert
   the performance into a list of MidiNote
-}


makeMIDINotes : Result String MidiPerformance -> MidiNotes
makeMIDINotes perfResult =
    case perfResult of
        Ok perf ->
            let
                fn =
                    makeMIDINote perf.ticksPerBeat

                defaultPace =
                    Basics.toFloat 500000

                line =
                    perf.lines
                        |> List.head
                        |> withDefault []
            in
                List.foldl fn ( [], defaultPace ) line
                    |> first
                    |> List.reverse

        Err err ->
            []


toPerformance : Result String MidiRecording -> Result String MidiPerformance
toPerformance r =
    Result.map fromRecording r
