# Manage colour keys

- `phw_key()` returns a stored key. The accessible copy of a key is
  called `name@accessible` (see
  [`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md)).

- `phw_keys()` lists every key as a data frame.

- `phw_key_set()` adds or changes colours by hand. If the key has an
  accessible copy, the colours go into it too, as when the copy is made:
  a colour of the default palette that isn't in `"accessible"` keeps the
  group's accessible colour, or takes the next free one.

- `phw_key_recolour()` reassigns a whole key from a new palette, keeping
  the group order and the colour of neutral groups such as "Other".
  Groups named after the palette's colours, as in `"rag"`, take those
  colours, as in
  [`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md).
  Use it on purpose, e.g. to move to the `"accessible"` palette, because
  every report after that changes.

- `phw_key_reset()` forgets a key (and its accessible copy), or all of
  them.

- `phw_key_file()` sets a CSV file that keys are read from and saved to,
  so colours stay the same across sessions and reports. Call it at the
  top of your script or in a setup chunk, or set
  `options(phwstyle.key_file = "...")`. Pointing it at another file, or
  at `NULL`, forgets the keys read from the old file, so each project
  keeps its own colours.

## Usage

``` r
phw_key(name)

phw_keys()

phw_key_set(name, values)

phw_key_recolour(name, palette = "accessible", neutral = default_neutral)

phw_key_reset(name = NULL)

phw_key_file(path)
```

## Arguments

- name:

  Key name.

- values:

  Named vector of colours, e.g. `c("65+" = "#285087")`.

- palette:

  Palette to reassign from.

- neutral:

  Group names that keep their colour, as in
  [`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md).
  Groups in mid grey keep it too.

- path:

  Path to the CSV file. `NULL` stops using a file.

## Value

`phw_key()`: a named vector (empty if the key doesn't exist).
`phw_keys()`: a data frame. `phw_key_set()` and `phw_key_recolour()`:
the updated key, invisibly. `phw_key_reset()` and `phw_key_file()`:
their input, invisibly.

## Examples

``` r
phw_key_set("sex_example", c(Female = "#FF5D0C", Male = "#285087"))
phw_key("sex_example")
#>    Female      Male 
#> "#FF5D0C" "#285087" 
phw_key_reset("sex_example")

# Keep keys with a project:
f <- tempfile(fileext = ".csv")
phw_key_file(f)
phw_colour_key(c("A", "B"), "demo")
#>         A         B 
#> "#285087" "#24A2B5" 
read.csv(f)
#>    key level  colour
#> 1 demo     A #285087
#> 2 demo     B #24A2B5
phw_key_file(NULL)
```
