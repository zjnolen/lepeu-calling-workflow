
configfile: "config/config-multidataset.yaml"


for module_name in config["datasets"]:
    module:
        name: module_name
        snakefile:
        pathvars:
            results=f"results/{module_name}"
            logs=f"logs/{module_name}"
        config: config[f"{module_name}"]
    use rule from module_name as module_name*
