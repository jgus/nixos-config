## Coding Standards ##

- Generally speaking, follow the style of existing code, unless a specific rule below overrides. (Rules below should guide revision of existing code as well.)
- If there's a best practice standard that is not part of these rules, you may suggest it to the user, but don't follow it until approved by the user.
- VSCode _will_ autoformat files after you edit them.

### Coding Standards for Nix Files ###

- Don't use `with` at the top of a file, _except_ `with builtins`.
- Generally, scope `with`, `let`, and function arguments to the smallest scope where they apply.
- Sort arguments declarations alphabetically, as well as anything else without an intrinsic order, or a logical organizational order
- Functions/modules should be organized like this:
  - `with builtins;` as the _first_ line of the file, iff builtins are used
  - let block with definitions that don't depend on arguments
  - arguments, sorted alphabetically
  - let block with definitions that _do_ depend on arguments
  - function body
- Prefer `lib.optional` instead of `if ... then [ ... ] else [ ]`; similarly with `lib.mkIf` and `lib.mkMerge`, etc.
- Comments should be only for non-obvious things. Avoid especially "Look I did what you asked!" comments.
- Prefer `inherit x;` over `x = x;`
- In contianer volume specifications, ensure secrets are always mounted with `:ro`
- my-lib.nix exists for reusable utiliy functions. That's a good place to add such a thing as needed.
