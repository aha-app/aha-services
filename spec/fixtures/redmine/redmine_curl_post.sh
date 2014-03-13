curl -v -H "X-Redmine-API-Key: 123456" -H "Accept: application/json" -H "Content-type: application/json" -d '{"issue":{"project_id":"2","subject":"dupa","tracker_id":"4","fixed_version_id":"2"}}' http://localhost:4000/issues.json

curl -v -H "Accept: application/json" -H "Content-type: application/json" -d '{"version":{"name":"Sprint 26"}}' http://aha.m.redmine.org/projects/1/versions.json?key=e79b0c758b08cd06e76204cf8806f407ff9c35ea
