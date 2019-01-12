[
  inputs: ["mix.exs", "{config,lib,test,web}/**/*.{ex,exs}"],
  import_deps: [:ecto, :phoenix, :plug],
  # The following `locals_without_parens` are used in a migration. ecto < 3.0
  # does not provide `locals_without_parens` for functions used in migrations.
  # They come only with ecto_sql which got introduced for use with ecto >= 3.0.
  locals_without_parens: [
    add: 2,
    create: 1
  ]
]
