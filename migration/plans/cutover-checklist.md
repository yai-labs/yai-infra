# Cutover Checklist

- [ ] PR CI verde su tutti i repo
- [ ] workflow_call pinned a tag (no main)
- [ ] Docs governance/process/migration presenti in yai-infra/docs
- [ ] Simulazione failure eseguita (tag inesistente) con rollback documentato
- [ ] Tag finale v0.1.0 creato e consumer aggiornati

## Milestones

- [x] Milestone `PHASE: infra-cutover@0.1.0` creata in tutti i repo YAI
- [x] Milestone `PHASE: infra-automation@0.1.1` creata in tutti i repo YAI
- [x] Issue cutover (`yai-infra#2-#8`) allineate a `infra-cutover@0.1.0`
- [x] Issue automazione (`yai-infra#9-#15`) allineate a `infra-automation@0.1.1`
- [x] PR rollout automazione milestone-tagged (`infra-automation@0.1.1`) in tutti i repo
- [ ] Issue hardening `yai-infra#17` completata (svuotamento non-core da `yai` verso `yai-infra`)
