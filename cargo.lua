local cargo = {}

local function merge(target, source, ...)
  if not target or not source then return target end
  for k, v in pairs(source) do target[k] = v end
  return merge(target, ...)
end

local la, lf, lg = love.audio, love.filesystem, love.graphics

local function makeFont(path)
  return function(size)
    return lg.newFont(path, size)
  end
end

cargo.loaders = {
  lua = dofile,
  png = lg and lg.newImage,
  jpg = lg and lg.newImage,
  dds = lg and lg.newImage,
  glsl = lg and lg.newShader,
  mp3 = la and la.newSource,
  ogg = la and la.newSource,
  wav = la and la.newSource,
  txt = lf and lf.read,
  ttf = lg and makeFont
}

cargo.processors = {}

function cargo.init(config)
  if type(config) == 'string' then
    config = {dir = config}
  end

  local loaders = merge({}, cargo.loaders, config.loaders)
  local processors = merge({}, cargo.processors, config.processors)

  local init

  local function halp(t, k)
    local path = t._path .. '/' .. k
    if lf.isDirectory(path) then
      rawset(t, k, init(path))
      return t[k]
    else
      for extension, loader in pairs(loaders) do
        local file = path .. '.' .. extension
        if lf.exists(file) then
          local asset = loader(file)
          rawset(t, k, asset)
          for pattern, processor in pairs(processors) do
            if file:match(pattern) then
              processor(asset, file, t)
            end
          end
          return asset
        end
      end
    end

    return rawget(t, k)
  end

  init = function(path)
    return setmetatable({_path = path}, {__index = halp})
  end

  return init(config.dir)
end

return cargo
