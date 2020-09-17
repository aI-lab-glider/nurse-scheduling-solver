## To run backend server execute a command:

1. Install all packages (only once)

  ```
  julia
  using Pkg
  Pkg.add("Genie")
  Pkg.add("HTTP")
  ```

2. Run the server

  ```
  julia backend.jl
  ```

## API

* POST /repaired_schedule

body - JSON schedule

response - JSON repaired_schedule

* POST /schedule_errors 

body - JSON schedule

response - JSON errors