#!/usr/bin/env coffee
http = require 'http'
cheerio = require 'cheerio'
{basename} = require 'path'

log = (s) -> process.stderr.write s + '\n'; return
err = (s) -> log 'ERROR: ' + s; process.exit 1; return

get = (host, path, callback) ->
  http.get {host, path}, (res) ->
    data = ''; res.setEncoding 'utf8'
    res.on 'data', (chunk) -> data += chunk; return
    res.on 'end', -> callback data; return
    return
  .on 'error', (e) -> console.error e; process.exit 1; return
  return

iso = ///^
  ┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬─────────┐.*\n
  │....│....│....│....│....│....│....│....│....│....│....│....│....│.........│.*\n
  │....│....│....│....│....│....│....│....│....│....│....│....│....│.........│.*\n
  ├────┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬──────┤.*\n
  │.......│....│....│....│....│....│....│....│....│....│....│....│....│......│.*\n
  │.......│....│....│....│....│....│....│....│....│....│....│....│....│......│.*\n
  ├───────┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┐.....│.*\n
  │........│....│....│....│....│....│....│....│....│....│....│....│....│.....│.*\n
  │........│....│....│....│....│....│....│....│....│....│....│....│....│.....│.*\n
  ├──────┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴────┴─────┤.*\n
  │......│....│....│....│....│....│....│....│....│....│....│....│............│.*\n
  │......│....│....│....│....│....│....│....│....│....│....│....│............│.*\n
  ├──────┴┬───┴─┬──┴───┬┴────┴────┴────┴────┴────┴┬───┴──┬─┴────┼─────┬──────┤.*
$///
ansi = ///^
  ┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬─────────┐.*\n
  │....│....│....│....│....│....│....│....│....│....│....│....│....│.........│.*\n
  │....│....│....│....│....│....│....│....│....│....│....│....│....│.........│.*\n
  ├────┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬──────┤.*\n
  │.......│....│....│....│....│....│....│....│....│....│....│....│....│......│.*\n
  │.......│....│....│....│....│....│....│....│....│....│....│....│....│......│.*\n
  ├───────┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴──────┤.*\n
  │........│....│....│....│....│....│....│....│....│....│....│....│..........│.*\n
  │........│....│....│....│....│....│....│....│....│....│....│....│..........│.*\n
  ├────────┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──────────┤.*\n
  │...........│....│....│....│....│....│....│....│....│....│....│............│.*\n
  │...........│....│....│....│....│....│....│....│....│....│....│............│.*\n
  ├───────┬───┴─┬──┴───┬┴────┴────┴────┴────┴────┴┬───┴──┬─┴────┼─────┬──────┤.*
$///

offsets = [1, 16, 30, 44] # scancode offsets rows http://www.abreojosensamblador.net/Productos/AOE/html/Pags_en/ApF.html

geom = _: 'iso'; layouts = {}; lcs = []

processContent = (data) ->
  cheerio.load(data)('pre').text()
    .replace /\r\n/g, '\n'
    .replace /\nDyalog APL\/([A-Z]{2}).*\n¯*\n(┌(?:.*\n){12}.*)/gm, (_, lc, desc) ->
      lcs.push lc; l = layouts[lc] = for [0..3] then for [0..57] then ' '
      if desc.match ansi then geom[lc] = 'ansi' else if !desc.match iso then err "unrecognized geometry for #{lc}"
      for line, i in desc.split '\n' when i % 3
        for chunk, j in line[1..73].split /[─│┌┬┐├┼┤└┴┘]+/g when chunk.length == 4
          if chunk[1] != ' ' || chunk[3] != ' ' then err "bad key in #{lc} -- #{JSON.stringify chunk}"
          for k in [0..2] by 2 then l[k + 2 - i % 3][offsets[Math.floor i / 3] + j] = chunk[k]
      for i in [0..3] then l[i] = l[i].join ''
      console.assert l[0].length == l[1].length == l[2].length == l[3].length
      return
  return

writeOutput = ->
  process.stdout.write """
    // generated by #{basename __filename}
    D.kbds = {
      geom: #{JSON.stringify geom},
      layouts: {
        #{lcs.sort().map((lc) ->
          l = layouts[lc]; "#{lc}: [\n      #{l.map(JSON.stringify).join ',\n      '},\n    ]"
        ).join ',\n    '}
      }
    };\n
  """
  return

get 'dfns.dyalog.com', '/n_keyboards.htm', (data) ->
  processContent data
  get 'dfns.dyalog.com', '/n_kbmac.htm.htm', (data) ->
    processContent data
    writeOutput()
    return
  return