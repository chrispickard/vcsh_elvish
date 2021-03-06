# bang-bang
#
# Emulate !! and !$ in Elvish to insert the last command and its last
# argument, respectively
# Diego Zamboni <diego@zzamboni.org>

# To use:
#     use bang-bang
#     bang-bang:bind-trigger-keys
#
# By default, bind-trigger-keys also binds the default "lastcmd" key (Alt-1),
# and when repeated, it will insert the full command. This means it
# fully emulates the default "lastcmd" behavior. If you want to disable
# this behavior or bind bang-bang to other keys, you can pass them in a list
# in the &extra-triggers option to bind-trigger-keys. For example, to
# avoid binding to the default "lastcmd" key (Alt-1):
#
#     bang-bang:bind-trigger-keys &extra-triggers=[]
#
# or to bind it to "Alt-`" instead:
#
#     bang-bang:bind-trigger-keys &extra-triggers=["Alt-`"]
#
# By default, Alt-! (Alt-Shift-1) can be used to insert an exclamation
# mark when you really need one. This works both from insert mode or
# from "bang-mode" after you have typed an exclamation mark. If you want
# to bind this to a different key, specify it with the &plain-bang
# option to bind-trigger-keys, like this:
#
#     bang-bang:bind-trigger-keys &plain-bang="Alt-3"
#

# Hooks to run before and after lastcmd
before-lastcmd = []
after-lastcmd = []

# Binding to insert a plain !, also works after entering lastcmd.
# Do not set directly, instead pass the &plain-bang option to
# bind-trigger-keys (defaults to "Alt-!")
plain-bang-insert = ""

# Additional keys that will trigger bang-bang mode. These keys
# will also be bound, when pressed twice, to inserting the full
# last command.
extra-trigger-keys = []

# Insert a plain exclamation mark
fn insert-plain-bang { edit:insert:start; edit:insert-at-dot "!" }

fn lastcmd {
  for hook $before-lastcmd { $hook }
  last = (edit:command-history -1)
  parts = [(edit:wordify $last[cmd])]
  cmd = [
    &content=$last[cmd]
    &display="! "$last[cmd]
	  &filter-text=""
  ]
  bang = [
    &content="!"
    &display=$plain-bang-insert" !"
    &filter-text=""
  ]
  index = 0
  extra = ""
  candidates = [$cmd ( each [arg]{
        if (eq $index (- (count $parts) 1)) {
          extra = "/$"
        }
	      put [
          &content=$arg
          &display=$index$extra" "$arg
          &filter-text=$index
	      ]
	      index = (+ $index 1)
  } $parts) $bang]
  bindings = [
    &!={ edit:insert:start; edit:insert-at-dot $last[cmd] }
    &"$"={ edit:insert:start; edit:insert-at-dot $parts[-1] }
    &$plain-bang-insert=$&insert-plain-bang
  ] 
  for k $extra-trigger-keys {
    bindings[$k] = { edit:insert:start; edit:insert-at-dot $last[cmd] }
  }
  edit:-narrow-read {
    put $@candidates
  } [arg]{
    edit:insert-at-dot $arg[content]
    for hook $after-lastcmd { $hook }
  } &modeline="bang-lastcmd " &auto-commit=$true &ignore-case=$true &bindings=$bindings
}

fn bind-trigger-keys [&plain-bang="Alt-!" &extra-triggers=["Alt-1"]]{
  plain-bang-insert = $plain-bang
  extra-trigger-keys = $extra-triggers
  edit:insert:binding[!] = $&lastcmd
  for k $extra-triggers {
    edit:insert:binding[$k] = $&lastcmd
  }
  edit:insert:binding[$plain-bang-insert] = $&insert-plain-bang
}
