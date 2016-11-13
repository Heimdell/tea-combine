module TeaCombine.Effectful
    exposing
        ( UpdateE
        , Subscription
        , updateBoth
        , updateEach
        , updateAll
        , (<>)
        , (<&>)
        , (<+>)
        )

import Array exposing (Array)
import Either exposing (Either(..))
import Tuple2 exposing (mapFst, mapSnd, mapEach)


-- local imports

import TeaCombine exposing (Both, Ix(..))


type alias UpdateE model msg =
    msg -> model -> ( model, Cmd msg )


type alias Subscription model msg =
    model -> Sub msg


updateBoth :
    UpdateE model1 msg1
    -> UpdateE model2 msg2
    -> UpdateE (Both model1 model2) (Either msg1 msg2)
updateBoth ul ur =
    let
        applyL f m =
            mapFst (f m) >> (\( ( x, c ), y ) -> ( ( x, y ), Cmd.map Left c ))

        applyR f m =
            mapSnd (f m) >> (\( x, ( y, c ) ) -> ( ( x, y ), Cmd.map Right c ))
    in
        Either.unpack (applyL ul) (applyR ur)


updateEach :
    (Int -> UpdateE model msg)
    -> UpdateE (Array model) (Ix msg)
updateEach updateAt (Ix idx msg) models =
    Array.get idx models
        |> Maybe.map
            (mapEach
                (flip (Array.set idx) models)
                (Cmd.map (Ix idx))
                << updateAt idx msg
            )
        |> Maybe.withDefault ( models, Cmd.none )


updateAll :
    List (UpdateE model msg)
    -> UpdateE (Array model) (Ix msg)
updateAll updates =
    let
        uarr =
            Array.fromList updates

        updateAt idx =
            Maybe.withDefault (\_ m -> ( m, Cmd.none ))
                (Array.get idx uarr)
    in
        updateEach (\_ _ m -> ( m, Cmd.none ))


(<&>) :
    UpdateE model1 msg1
    -> UpdateE model2 msg2
    -> UpdateE (Both model1 model2) (Either msg1 msg2)
(<&>) =
    updateBoth


(<>) :
    ( model1, Cmd msg1 )
    -> ( model2, Cmd msg2 )
    -> ( Both model1 model2, Cmd (Either msg1 msg2) )
(<>) ( m1, c1 ) ( m2, c2 ) =
    ( ( m1, m2 )
    , Cmd.batch
        [ Cmd.map Left c1
        , Cmd.map Right c2
        ]
    )


(<+>) :
    Subscription model1 msg1
    -> Subscription model2 msg2
    -> Subscription (Both model1 model2) (Either msg1 msg2)
(<+>) s1 s2 ( m1, m2 ) =
    Sub.batch
        [ Sub.map Left <| s1 m1
        , Sub.map Right <| s2 m2
        ]