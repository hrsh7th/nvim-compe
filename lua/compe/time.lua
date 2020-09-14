local Time = {}

function Time:clock()
  return os.clock() * 10 * 1000
end

return Time

