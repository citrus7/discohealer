function Disco_queue_pushLeft(list, value)
  local first = list._first - 1
  list._first = first
  list[first] = value
end

function Disco_queue_pushRight(list, value)
  local last = list._last + 1
  list._last = last
  list[last] = value
end

function Disco_queue_popLeft(list)
  local first = list._first
  --if first > list._last then return; end
  local value = list[first]
  list[first] = nil
  list._first = first + 1
  return value
end

function Disco_queue_popRight(list)
  local last = list._last
  --if list._first > last then return; end
  local value = list[last]
  list[last] = nil
  list._last = last - 1
  return value
end