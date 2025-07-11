
-- # add triggers

-- ## TABLE projects
CREATE TRIGGER insert_project_post_process
AFTER INSERT ON projects
FOR EACH ROW EXECUTE PROCEDURE insert_project_post_process();


