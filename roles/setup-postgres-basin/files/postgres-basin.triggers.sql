
-- # add triggers

-- ## TABLE projects
CREATE TRIGGER insert_project
AFTER INSERT ON projects
FOR EACH ROW EXECUTE PROCEDURE insert_project();


