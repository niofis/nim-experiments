import threadpool, os

proc doSomething(id:int) =
  sleep 1000
  echo id

for x in 1..5:
  spawnX doSomething(x)

sync()
