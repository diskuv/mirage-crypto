let std_flags = ["-Wall"]

let () =
  let c = Configurator.V1.create "mirage-crypto" in
  let ccomp_type_opt = Configurator.V1.ocaml_config_var c "ccomp_type" in
  let arch =
    let defines =
      Configurator.V1.C_define.import
        c
        ~includes:[]
        [("__x86_64__", Switch); ("__i386__", Switch); ("_WIN64", Switch); ("_WIN32", Switch)]
    in
    match defines with
    | (_, Switch true) :: _ -> `x86_64
    | _ :: (_, Switch true) :: _ -> `x86
    | _ :: _ :: (_, Switch true) :: _ -> `x86_64
    | _ :: _ :: _ :: (_, Switch true) :: _ -> `x86
    | _ -> `unknown
  in
  let accelerate_flags =
    match arch, ccomp_type_opt with
    | `x86_64, Some ccomp_type when ccomp_type = "msvc" -> [ "-DACCELERATE" ]
    | `x86_64, _ -> [ "-DACCELERATE"; "-mssse3"; "-maes"; "-mpclmul" ]
    | _ -> []
  in
  let ent_flags =
    match arch, ccomp_type_opt with
    | (`x86_64 | `x86), Some ccomp_type when ccomp_type = "msvc" -> [ "-DENTROPY" ]
    | (`x86_64 | `x86), _ -> [ "-DENTROPY"; "-mrdrnd"; "-mrdseed" ]
    | _ -> []
  in
  let lang_flags =
    match ccomp_type_opt with
    | Some ccomp_type when ccomp_type = "msvc" -> ["/std:c11"]
    | _ -> ["--std=c11"]
  in
  let warn_flags =
    match ccomp_type_opt with
    | Some ccomp_type when ccomp_type = "msvc" -> []
    | _ -> ["-Wextra"; "-Wpedantic"]
  in
  let optimization_flags =
    match ccomp_type_opt with
    | Some ccomp_type when ccomp_type = "msvc" -> ["-O2"]
    | _ -> ["-O3"]
  in
  let flags = std_flags @ ent_flags @ lang_flags @ warn_flags @ optimization_flags in
  let opt_flags = flags @ accelerate_flags in
  Configurator.V1.Flags.write_sexp "cflags_optimized.sexp" opt_flags;
  Configurator.V1.Flags.write_sexp "cflags.sexp" flags
