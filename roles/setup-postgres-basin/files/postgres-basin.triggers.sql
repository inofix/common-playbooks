
-- # add triggers

-- ## TABLE projects
CREATE OR REPLACE TRIGGER insert_project_post_process
AFTER INSERT ON projects
FOR EACH ROW
    EXECUTE FUNCTION insert_project_post_process();

CREATE OR REPLACE TRIGGER set_ltree_path
BEFORE INSERT OR UPDATE ON shadow_sources
FOR EACH ROW
    EXECUTE FUNCTION update_ltree_path();

