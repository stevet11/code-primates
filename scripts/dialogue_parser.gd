extends RefCounted
## Parses a dialogue script (see assets/README.md for the format) into
## { node_label: [ item, ... ] } where each item is a Dictionary:
##   {type:"say", speaker, text}
##   {type:"cmd", cmd, arg}                        ! set / clear / give / take
##   {type:"goto", target, conds}                  -> target [if cond]
##   {type:"choice", text, target, conds, once, key}   * text -> target [if cond] [once]

static func parse(dialogue_id: String, src: String) -> Dictionary:
	var nodes := {}
	var cur = null
	var tag_re := RegEx.create_from_string("\\[(?:if\\s+([^\\]]+)|(once))\\]")
	var say_re := RegEx.create_from_string("^([^:]{1,40}):\\s*(.+)$")
	var n := 0
	for raw in src.split("\n"):
		n += 1
		var line := raw.strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		if line.begins_with("=="):
			var label := line.trim_prefix("==").strip_edges()
			cur = []
			nodes[label] = cur
			continue
		if cur == null:
			push_error("%s:%d: line before any '== label'" % [dialogue_id, n])
			continue
		if line.begins_with("*") or line.begins_with("->"):
			# pull out [if ...] and [once] tags
			var conds: Array[String] = []
			var once := false
			for m in tag_re.search_all(line):
				if m.get_string(2) == "once":
					once = true
				else:
					conds.append(m.get_string(1).strip_edges())
			line = tag_re.sub(line, "", true).strip_edges()
			if line.begins_with("->"):
				cur.append({"type": "goto", "target": line.trim_prefix("->").strip_edges(), "conds": conds})
			else:
				var parts := line.substr(1).rsplit("->", true, 1)
				if parts.size() < 2:
					push_error("%s:%d: choice needs '-> target'" % [dialogue_id, n])
					continue
				cur.append({"type": "choice", "text": parts[0].strip_edges(),
						"target": parts[1].strip_edges(), "conds": conds, "once": once,
						"key": "dlg:%s:%d:%d" % [dialogue_id, nodes.size(), cur.size()]})
		elif line.begins_with("!"):
			var bits := line.substr(1).strip_edges().split(" ", false, 1)
			if bits.size() < 2:
				push_error("%s:%d: command needs an argument" % [dialogue_id, n])
				continue
			cur.append({"type": "cmd", "cmd": bits[0], "arg": bits[1].strip_edges()})
		else:
			var m := say_re.search(line)
			if m == null:
				push_error("%s:%d: can't parse '%s'" % [dialogue_id, n, line])
				continue
			cur.append({"type": "say", "speaker": m.get_string(1).strip_edges(), "text": m.get_string(2).strip_edges()})
	return nodes
