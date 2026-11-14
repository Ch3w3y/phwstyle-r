# Manage colour keys

- `phw_key()` returns a stored key. The accessible copy of a key is
  called `name@accessible` (see
  [`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md)).

- `phw_keys()` lists every key as a data frame.

- `phw_key_set()` adds or changes colours by hand.

- `phw_key_recolour()` reassigns a whole key from a new palette, keeping
  the group order. Use it on purpose, e.g. to move to the `"accessible"`
  palette, because every report after that changes.

- `phw_key_reset()` forgets a key (and its accessible copy), or all of
  them.

- `phw_key_file()` sets a CSV file that keys are read from and saved to,
  so colours stay the same across sessions and reports. Call it at the
  top of your script or in a setup chunk, or set
  `options(phwstyle.key_file = "...")`.

## Usage

``` r
phw_key(name)

phw_keys()

phw_key_set(name, values)

phw_key_recolour(name, palette = "accessible")

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

- path:

  Path to the CSV file. `NULL` stops using a file.

## Value

`phw_key()`: a named vector (empty if the key doesn't exist).
`phw_keys()`: a data frame. The others return their input invisibly.

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
