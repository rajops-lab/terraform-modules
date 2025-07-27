ENVS := dev stage prod
ACTIONS := init plan apply validate

$(foreach env,$(ENVS), \
  $(foreach action,$(ACTIONS), \
    $(eval $(action)-$(env): \
      ; cd env/$(env) && terraform $(action) $(if $(filter $(action),plan apply),-var-file="$(env).tfvars",)) \
  ) \
)

