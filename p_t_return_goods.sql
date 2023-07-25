USE [test_db]

--PROCEDURE ins_goods_return

GO
ALTER PROCEDURE p_t_return_goods
	@Operation VARCHAR(10),
    @return_id INT = NULL,
    @item_id int = NULL,
    @cust_id int = NULL,
	@reason_return nvarchar(200) = NULL,
	@date_return DATE = NULL
    
AS
BEGIN
	
	set nocount on
	
	if @Operation = 'CREATE'
	begin
	CREATE TABLE t_return_goods
	(
		return_id INT PRIMARY KEY,
		item_id INT ,
		cust_id int,
		date_return date,
		reason_return nvarchar(200)
	)
	end

    -- Search operation
    IF @Operation = 'SEARCH'
    BEGIN
        SELECT *
        FROM t_return_goods
        WHERE return_id = @return_id
    END

    -- Add operation
    IF @Operation = 'INSERT'
    BEGIN
		set @date_return = GETDATE()
		--check for existing name
		if exists(select * from t_return_goods where return_id = @return_id)
		begin
			RAISERROR('return id already existed', 16, 1)
			return 1
		end
		
		begin transaction
        INSERT INTO t_return_goods (return_id, item_id, cust_id, date_return, reason_return)
        VALUES (@return_id, @item_id, @cust_id, @date_return, @reason_return)
		if @@ERROR != 0 or @@ROWCOUNT = 0
		begin
			RAISERROR('failed to add or no row effected', 16,1 )
			rollback transaction
			return 1
		end
		commit transaction
		return 0
    END

    -- Update operation
    IF @Operation = 'UPDATE'
    BEGIN
		begin transaction
        UPDATE t_return_goods
        SET
            item_id = ISNULL(@item_id, item_id),
            cust_id = ISNULL(@cust_id, cust_id),
			date_return = ISNULL(@date_return, date_return),
			reason_return = ISNULL(@reason_return, reason_return)
        WHERE
            return_id = @return_id
		if @@ERROR != 0 or @@ROWCOUNT = 0
		begin
			RAISERROR('Failed to update', 16, 1)
			rollback transaction
			return 1
		end
		commit transaction
		return 0
    END

    -- Delete operation
    IF @Operation = 'DELETE'
    BEGIN
		begin transaction
        DELETE FROM t_return_goods
        WHERE return_id = @return_id
		if @@ERROR != 0 or @@ROWCOUNT = 0
		begin
			RAISERROR('Failed to delete or no row affected', 16, 1)
			rollback transaction
			return 1
		end
		commit transaction
		return 0
    END
END

exec p_t_return_goods 'CREATE'
EXEC p_t_return_goods 'SEARCH' , 1
EXEC p_t_return_goods 'INSERT', 1, 1, 1, 'refund'
EXEC p_t_return_goods 'INSERT', 2, 2, 2, 'broken on delivery'

EXEC p_t_return_goods 'UPDATE', 1, 1, 1, 'wrong item'
EXEC p_t_return_goods 'DELETE', 2

select * from t_return_goods
drop table t_return_goods




-----------------------------------------------------------------------


GO
ALTER PROCEDURE p_t_state
	@Action nvarchar(20),
	@state_name nvarchar(100) = null,
	@country_id int = null,
	@state_id int = null,
	@res int = null output
	
AS
begin
	set nocount on

	if @Action = 'CREATE'
	begin
	begin transaction
	create table t_state(
				id int NOT NULL IDENTITY PRIMARY KEY, --set id as primary auto increase
				state_name nvarchar(100) NOT NULL,
				country_id int)

	if @@ERROR != 0
	begin
		RAISERROR('FAILED TO CREATE TABLE', 16, 1)
		ROLLBACK
		RETURN 1
	end
	commit transaction
	return 0
	end


	if @Action = 'INSERT'
	begin
		if exists(select*from t_state where state_name= @state_name)
		begin
			RAISERROR ('state name already exist', 16, 1)
			return 1
		end
		begin transaction
		INSERT INTO t_state (state_name, country_id)
		VALUES (@state_name, @country_id)
		if @@ERROR != 0 or @@ROWCOUNT = 0
		begin
			RAISERROR('Failed or no row affected', 16, 1)
			rollback transaction
			return 1
		end
		commit transaction
		return 0
	end

	IF @Action = 'UPDATE'
    BEGIN
		begin transaction
        UPDATE t_state
        SET
            state_name = ISNULL(@state_name, state_name),
            country_id = ISNULL(@country_id, country_id)
        WHERE
            id = @state_id
		if @@ERROR != 0 or @@ROWCOUNT = 0
		begin
			RAISERROR('Failed to update', 16, 1)
			rollback transaction
			return 1
		end
		commit transaction
		return 0
    END

	if @Action='DEL'
	begin
		begin transaction
		DELETE FROM t_state where state_name = @state_name
		if @@ERROR != 0 or @@ROWCOUNT = 0
		begin
			RAISERROR('FAILED - data either doesnt exist', 16, 1)
			ROLLBACK
			return 1
		end
		commit transaction
		declare @a int
		SELECT @a = MAX(id) FROM t_state
		SET @a = ISNULL(@a, 0)
		DBCC CHECKIDENT ('t_state', RESEED, @a);
		return 0
	end

	if @Action = 'SEARCH'
	begin
		SELECT * FROM t_state where state_name = @state_name
		SELECT @res = id FROM t_state WHERE state_name = @state_name
		RETURN @res
	end
end


drop table t_state

exec p_t_state 'CREATE'

exec p_t_state 'INSERT', 'sandakan', 1
exec p_t_state 'INSERT', 'tawau', 1
exec p_t_state 'INSERT', 'keningau', 1

exec p_t_state 'DEL', 'keningau', 1
exec p_t_state 'DEL', 'tawau', 1
exec p_t_state 'INSERT', 'Semporna', 1
exec p_t_state 'DEL', 'LD', 1

exec p_t_state 'UPDATE', 'semporna', 1, 5

declare @return_value int
exec @return_value = p_t_state 'SEARCH', 'tawau'
select 'Return Value' = @return_value

exec t_state_ins 3, 'tawau', 1

select * from t_state


