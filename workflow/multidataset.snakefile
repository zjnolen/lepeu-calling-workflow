
configfile: "config/config-multidataset.yaml"


rule all:
    input:
        collect(
            "results/{dataset}/bcfs/{caller}/{mapper}_{caller}.bcf",
            dataset=config["datasets"],
            mapper=config["mappers"],
            caller=config["callers"],
        )

for module_name in config["datasets"]:
    alias = f"{module_name}_"
    module:
        name: module_name
        snakefile: "snakefile"
        pathvars:
            results=f"results/{module_name}",
            logs=f"logs/{module_name}"
        config: config[f"{module_name}"] | {"mappers": config["mappers"]} | {"callers": config["callers"]}
    use rule * from module_name exclude all as alias*
