import  threadpool,
        sequtils,
        os,
        math,
        random

#proc pmap[T, S](data:openArray[T]; op: proc(x: T): S): seq[S] =
#  var output = newSeq[S](data.len())
#  parallel:
#    for i in 0..<data.len():
#      output[i] = op(data[i])
#  return output

#Based on code from here:
#http://blog.ubergarm.com/10-nim-one-liners-to-impress-your-friends/
proc pMap*[T, S](data: openArray[T], op: proc (x: T): S {.closure,thread.}): seq[S]{.inline.} =
    newSeq(result, data.len)
    var vals = newSeq[FlowVar[S]](data.len)

    for i in 0..data.high:
        vals[i] = spawn op(data[i])

    for i in 0..data.high:
        var res = ^vals[i]
        result[i] = res


proc doWork(x: int): int =
    # sleep and print just to show it's actually parallel
    os.sleep(1000)
    echo x
    return 2 * x

echo toSeq(1..10).pMap(doWork)

let
  a = @[1, 2, 3, 4]
  b = pMap(a, proc(x: int): string = $x)
echo a
echo b
assert b == @["1", "2", "3", "4"]
