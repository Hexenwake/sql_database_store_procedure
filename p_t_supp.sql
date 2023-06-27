USE test_db

GO
ALTER PROCEDURE p_t_supp_inf
	@Action nvarchar(10),
	@supp_name nvarchar(100) = null,
	@supp_email nvarchar(100) = null,
	@supp_phone int = null,
	@state_name nvarchar(50) = null,
	@edit_supp_name nvarchar(100) = null,
	@res int = null output
	
AS
begin
	set nocount on

	if @Action = 'CREATE_T'
	begin
	if not exists(select object_id from sys.tables
		where name = 't_supp_info'
		and SCHEMA_NAME(schema_id) = 'dbo')
		begin
			PRINT 'Table doesnt exist -- creating table'
			create table t_supp_info(
				id int NOT NULL IDENTITY PRIMARY KEY, --set id as primary auto increase
				supp_name nvarchar(100) NOT NULL,
				supp_email nvarchar(100),
				supp_phone int,
				state_id int FOREIGN KEY REFERENCES t_state(id))
		end
	end

	if @Action = 'INSERT'
	begin
		declare @a int
		exec @a = p_t_state 'SEARCH', @state_name
		if @a = 0 --check if @a is null or not
		begin
			exec p_t_state 'INSERT', @state_name
			exec @a = p_t_state 'SEARCH', @state_name
		end

		if exists(select*from t_supp_info where supp_name= @supp_name)
		begin
			RAISERROR ('supplier name already exist', 16, 1)
			return 1
		end

		begin transaction
		INSERT INTO t_supp_info (supp_name, supp_email, supp_phone, state_id)
		VALUES (@supp_name, @supp_email, @supp_phone, @a)
		if @@ERROR != 0 or @@ROWCOUNT = 0
		begin
			RAISERROR('Failed or no row affected', 16, 1)
			rollback transaction
			return 1
		end
		commit transaction
		return 0
	end

	if @Action='DEL'
	begin
		begin transaction
		DELETE FROM t_supp_info where supp_name = @supp_name
		if @@ERROR != 0
		begin
			RAISERROR('FAILED', 16, 1)
			ROLLBACK
			return 1
		end
		commit transaction
		declare @i int
		SELECT @i = MAX(id) FROM t_supp_info
		SET @i = ISNULL(@i, 0)
		DBCC CHECKIDENT ('t_supp_info', RESEED, @i);
		return 0
	end

	if @Action='UPDATE'
	begin
		set @state_name = ISNULL(@state_name,
		(SELECT a.state_name from t_state a, t_supp_info b where a.id = b.state_id AND b.supp_name = @supp_name))

		declare @b int
		set @b = (SELECT id FROM t_state WHERE state_name = @state_name)
		if @@ROWCOUNT = 0
		begin
			RAISERROR('state_name doesnt exist', 16, 1)
			return 1
		end

		--retrieve id
		declare @id int
		select @id = id from t_supp_info where supp_name = @supp_name

		begin transaction
		update t_supp_info set
			supp_name = isnull(@edit_supp_name, supp_name),
			supp_email= isnull(@supp_email, supp_email),
			supp_phone= isnull(@supp_phone, supp_phone),
			state_id = isnull(@b, state_id)
		WHERE supp_name = @supp_name
		if @@ERROR != 0
		begin
			RAISERROR('FAILED', 16, 1)
			ROLLBACK
			return 1
		end
		commit transaction
		return 0
	end

	if @Action='SEARCH'
	begin
		SELECT * FROM t_supp_info where supp_name = @supp_name
		SELECT @res = id FROM t_supp_info where supp_name = @supp_name
		RETURN @res
	end

end

exec p_t_supp_inf 'INSERT', 'harrison', '', 123121234, 'Semporna'
exec p_t_supp_inf 'INSERT', 'aiman', 'aiman@example.com', 3214151, 'tawau'
exec p_t_supp_inf 'INSERT', 'danesh', '', 0113113142, 'keningau'

exec p_t_supp_inf 'DEL', 'harrison'
exec p_t_supp_inf 'DEL', 'test'
exec p_t_supp_inf 'DEL', 'harold'



exec p_t_supp_inf 'UPDATE', 'harrison', 'harrison@gmail.com', 011, 'sandakan', 'harold'
exec p_t_supp_inf 'UPDATE', 'test', 'test@gmail.com', null, null, 'test2'

exec p_t_supp_inf 'SEARCH', 'harold'
exec p_t_supp_inf 'SEARCH', 'aiman'

exec p_t_item_info 'UPDATE', 1, null, null, 3

select * from t_supp_info


select * from t_state
select * from t_item_info
select * from t_return_goods
select * from t_cust

SELECT a.return_id, a.reason_return, a.date_return, 
b.item_name, b.price, c.cust_name, c.cust_email
FROM t_return_goods a, t_item_info b, t_cust c
WHERE a.item_id = b.item_id AND a.cust_id = c.cust_id


exec p_t_return_goods 'UPDATE', 2, 2, 1, 'broken'