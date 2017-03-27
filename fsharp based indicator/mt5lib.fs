#nowarn "9"
namespace mt5lib
open System
open FSharp.NativeInterop
open System.Runtime.InteropServices
open RGiesecke.DllExport

type Util() =

    [<DllExport("BandsCustomed", CallingConvention = CallingConvention.StdCall)>]
    static member BandsCustomed ( [<MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 1s)>] prices : double[] ,
                                  pricesSize :     int ,
                                  prevCalculated : int ,
                                  [<In; Out; MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 1s)>] ema10Buffer : double[] ,
                                  [<In; Out; MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 1s)>] sma13Buffer : double[] ,
                                  [<In; Out; MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 1s)>] ema25Buffer : double[] ,
                                  [<In; Out; MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 1s)>] upperBuffer : double[] ,
                                  [<In; Out; MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 1s)>] lowerBuffer : double[]
                                ) : unit =

        Util.EMA( prices,10,prevCalculated, ema10Buffer )
        Util.SMA( prices,13,prevCalculated, sma13Buffer )
        Util.EMA( prices,25,prevCalculated, ema25Buffer )
        Util.Bands( prices, prevCalculated, ema25Buffer, upperBuffer, lowerBuffer)


    static member SMA ( prices:          array<double>,
                        period:          int,
                        prevCalculated:  int,
                        extMovingBuffer: array<double>
                      ) : unit =

        let ratesTotal = Array.length prices

        let limit = match prevCalculated = 0 with
                    | false -> prevCalculated - 1
                    | true  ->
                        [0 .. ( period - 1 )]
                        |> List.sumBy ( fun i -> prices.[i] )
                        |> fun x -> x / double period
                        |> fun x -> extMovingBuffer.[period - 1] <- x
                        |> ignore
                        period

        [limit .. ( ratesTotal - 1 )]
        |> List.map ( fun i -> extMovingBuffer.[i] <- extMovingBuffer.[i-1] + ( prices.[i] - prices.[i - period] ) / double period  )
        |> ignore


    static member EMA ( prices:          array<double>,
                        period:          int,
                        prevCalculated:  int,
                        extMovingBuffer: array<double>
                      ) : unit =

        let ratesTotal = Array.length prices
        let smoothFactor = 2.0 / (1.0 + double period )

        let limit = match prevCalculated = 0 with
                    | false -> prevCalculated - 1
                    | true  ->
                        extMovingBuffer.[0] <- prices.[0]

                        [1 .. ( period - 1 )]
                        |> List.map (fun i -> extMovingBuffer.[i] <- prices.[i] * smoothFactor + extMovingBuffer.[i-1] * (1.0 - smoothFactor))
                        |> ignore

                        period

        [limit .. ( ratesTotal - 1 )]
        |> List.map ( fun i -> extMovingBuffer.[i] <- prices.[i] * smoothFactor + extMovingBuffer.[i-1] * (1.0 - smoothFactor) )
        |> ignore


    static member Bands ( prices:          array<double>,
                          prevCalculated:  int,
                          extMovingBuffer: array<double>,
                          extUpperBuffer:  array<double>,
                          extLowerBuffer:  array<double>
                        ):unit =

        let bandsDeviations = 2.
        let period = 25

        let ratesTotal = Array.length prices
        let pos : int =
            if   prevCalculated > 1
            then prevCalculated - 1
            else 0

        //--- calculate StdDev
        [pos .. ( ratesTotal - 1 )]
        |> List.iter ( fun position ->
            let mutable stdDev_dTmp : double = 0.0
            if position >= period then
                [0 .. (period - 1)]
                |> List.sumBy ( fun i -> Math.Pow( prices.[position-i] - extMovingBuffer.[position], 2.) )
                |> fun x -> stdDev_dTmp <- Math.Sqrt( x / double period )
                |> ignore

            extUpperBuffer.[position] <- extMovingBuffer.[position] + bandsDeviations * stdDev_dTmp
            extLowerBuffer.[position] <- extMovingBuffer.[position] - bandsDeviations * stdDev_dTmp
            )


    [<DllExport("SetGridValue", CallingConvention = CallingConvention.StdCall)>]
    static member SetGridValue ( [<MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 1s)>] dammyArray : int[] ,
                                 accessableArraySize: int,
                                 highPrice :  double,
                                 lowPrice  :  double,
                                 point     :  double,
                                 gridSpace :  int,
                                 [<In; Out; MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 1s)>] arr : double[]
                               ) : unit =

        let divisor = 0.1 / point
        let step    = gridSpace / 10

        let high = int ( highPrice * divisor )
        let low  = int ( lowPrice  * divisor )

        [low .. high]
        |> Seq.filter ( fun price -> price % step = 0 )
        |> Seq.map    ( fun price -> float price / divisor  )
        |> Seq.iteri  ( fun i n -> arr.[i] <- n)
        |> ignore


    [<DllExport("GridNumber", CallingConvention = CallingConvention.StdCall)>]
    static member GridNumber ( [<MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 1s)>] dammyArray : int[] ,
                                accessableArraySize: int,
                                highPrice : double,
                                lowPrice  : double,
                                point     : double,
                                gridSpace : int
                             ) : int =

        let divisor = 0.1 / point
        let step    = gridSpace / 10

        let high = int ( highPrice * divisor )
        let low  = int ( lowPrice  * divisor )

        [low .. high]
        |> Seq.filter ( fun price -> price % step = 0 )
        |> fun l -> Seq.length l
