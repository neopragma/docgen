drop table if exists "document_sets";
create table if not exists "document_sets" (
    "id" integer not null,
    "name" varchar(128) not null,
    "description" varchar(256));
insert into document_sets ("id", "name", "description")
	values (1, "default", "Default document set when none is specified");
insert into document_sets ("id", "name", "description")
	values (2, "gcpd", "Gotham City Police Department");

drop table if exists "substitutions";
create table if not exists "substitutions" (
    "set_id" integer not null,
    "key" varchar(128) not null,
    "value" varchar(128) not null);

/* Defaults */
insert into substitutions ("set_id", "key", "value") 
	values ("default", "client name", "LeadingAgile");
insert into substitutions ("set_id", "key", "value") 
	values ("default", "tlt", "Transformation Leadership Team");
insert into substitutions ("set_id", "key", "value") 
	values ("default", "ivt", "Innovation and Verification Team");
insert into substitutions ("set_id", "key", "value") 
	values ("default", "value stream", "Line of Business");
insert into substitutions ("set_id", "key", "value") 
	values ("default", "portfolio team", "Portfolio Team");
insert into substitutions ("set_id", "key", "value") 
	values ("default", "program team", "Program Team");
insert into substitutions ("set_id", "key", "value") 
	values ("default", "delivery team", "Delivery Team");
insert into substitutions ("set_id", "key", "value") 
	values ("default", "iteration", "Sprint");
insert into substitutions ("set_id", "key", "value") 
	values ("default", "product owner", "Product Owner");

/* Gotham City Police Department */
insert into substitutions ("set_id", "key", "value") 
	values ("gcpd", "client name", "Gotham City Police Dept.");
insert into substitutions ("set_id", "key", "value") 
	values ("gcpd", "tlt", "Improvement Guidance Committee");
insert into substitutions ("set_id", "key", "value") 
	values ("default", "ivt", "Architectural Guidance Committee");
insert into substitutions ("set_id", "key", "value") 
	values ("gcpd", "value stream", "Product Line");
insert into substitutions ("set_id", "key", "value") 
	values ("gcpd", "portfolio team", "Product Line Team");
insert into substitutions ("set_id", "key", "value") 
	values ("gcpd", "program team", "Coordination Team");
insert into substitutions ("set_id", "key", "value") 
	values ("gcpd", "delivery team", "Development Pod");
insert into substitutions ("set_id", "key", "value") 
	values ("gcpd", "iteration", "Development Cadence");
insert into substitutions ("set_id", "key", "value") 
	values ("gcpd", "product owner", "Capability Owner");
