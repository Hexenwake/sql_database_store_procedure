use test_db

GO
ALTER PROCEDURE p_t_item_info
	@operation VARCHAR(10),
	@item_id int = NULL,
    @item_name VARCHAR(50) = NULL,
    @price float = NULL,
    @supp_id int = NULL,
    @state_name nvarchar(50) = NULL
    
AS
BEGIN
	set nocount on

	--create table function 
	if @operation = 'CREATE'
	begin
		CREATE TABLE t_item_info(
				item_id INT PRIMARY KEY,
				[item_name] nvarchar(50),
				[price] float,
				[supp_id] INT,
				[state_id] INT)
	end

    -- Search operation
    IF @Operation = 'SEARCH'
    BEGIN
        SELECT * FROM t_item_info WHERE item_name = @item_name
		RETURN 0
    END

	if @Operation = 'INSERT'
	begin
		-- check for state name to retrieve id
		declare @a int
		exec @a = p_t_state 'SEARCH', @state_name
		if @a = 0
		begin
			exec p_t_state 'INSERT', @state_name
			exec @a = p_t_state 'SEARCH', @state_name
		end

		if exists(select*from t_item_info where item_id= @item_id)
		begin
			RAISERROR ('item id already exist', 16, 1)
			return 1
		end

		begin transaction
		INSERT INTO t_item_info (item_id, item_name, price, supp_id, state_id)
		VALUES (@item_id, @item_name, @price, @supp_id, @a)
		if @@ERROR != 0 or @@ROWCOUNT = 0
		begin
			RAISERROR('Failed or no row affected', 16, 1)
			rollback transaction
			return 1
		end
		commit transaction
		return 0
	end

    -- Update operation
    IF @Operation = 'UPDATE'
    BEGIN
		
		if isnull(@state_name, '') != ''
		begin
			declare @b int
			exec @b = p_t_state 'SEARCH', @state_name
		end

        UPDATE t_item_info
        SET
            item_name = ISNULL(@item_name, item_name),
            price = ISNULL(@price, price),
            supp_id = ISNULL(@supp_id, supp_id),
            state_id = ISNULL(@b, state_id)
        WHERE
            item_id = @item_id
    END

    -- Delete operation
    IF @Operation = 'DELETE'
    BEGIN
		begin transaction
		DELETE FROM t_item_info WHERE item_id = @item_id
		if @@ERROR != 0 or @@ROWCOUNT = 0
		begin
			RAISERROR('failed or no row affected', 16, 1)
			rollback transaction
			return 1
		end
		commit transaction
		if not exists (select * from t_item_info)
		return 0
    END
END

exec p_t_item_info 'CREATE'
exec p_t_item_info 'INSERT', 1, 'gaming mouse', 98.45, 1, 'sandakan'
exec p_t_item_info 'INSERT', 2, 'bomb', 2.00, 2, 'kk'

exec p_t_state 'SEARCH', 'sandakan'

exec p_t_item_info 'UPDATE', 2, 'nasi ayam', 54.30, 1, 'sandakan'
exec p_t_item_info 'UPDATE', 2, 'bomb', 54.30, 1, 'kk'

exec p_t_item_info 'DELETE', 2

select * from t_item_info
select * from t_state

drop table t_item_info




----CUSTORMER INFO


GO
ALTER PROCEDURE p_t_cust
	@Operation VARCHAR(10),
    @cust_id INT = NULL,
    @cust_name VARCHAR(32) = NULL,
    @cust_phone int = NULL,
    @cust_email VARCHAR(50) = NULL,
	@state_name nvarchar(50) = NULL
    
AS
BEGIN
	
	set nocount on
	
	if @Operation = 'CREATE'
	begin
	CREATE TABLE t_cust
	(
		cust_id INT PRIMARY KEY,
		cust_name VARCHAR(32),
		cust_phone int,
		cust_email VARCHAR(50),
		state_id int
	)
	end

    -- Search operation
    IF @Operation = 'SEARCH'
    BEGIN
        SELECT *
        FROM t_cust
        WHERE cust_name = @cust_name
    END

    -- Add operation
    IF @Operation = 'INSERT'
    BEGIN
		--check for existing name
		if exists(select * from t_cust where cust_name = @cust_name)
		begin
			RAISERROR('Name already existed', 16, 1)
			return 1
		end

		declare @a int
		exec @a = p_t_state 'SEARCH', @state_name
		if @a = 0
		begin
			exec p_t_state 'INSERT', @state_name
			exec @a = p_t_state 'SEARCH', @state_name
		end
		
		begin transaction
        INSERT INTO t_cust (cust_id, cust_name, cust_phone, cust_email, state_id)
        VALUES (@cust_id, @cust_name, @cust_phone, @cust_email, @a)
		if @@ERROR != 0 or @@ROWCOUNT = 0
		begin
			RAISERROR('failed or no row effected', 16,1 )
			rollback transaction
			return 1
		end
		commit transaction
		return 0
    END

    -- Update operation
    IF @Operation = 'UPDATE'
    BEGIN
		if isnull(@state_name, '') != ''
		begin
			declare @b int
			exec @b = p_t_state 'SEARCH', @state_name
		end

		begin transaction
        UPDATE t_cust
        SET
            cust_name = ISNULL(@cust_name, cust_name),
            cust_phone = ISNULL(@cust_phone, cust_phone),
			cust_email = ISNULL(@cust_email, cust_email),
			state_id = ISNULL(@b, state_id)
        WHERE
            cust_id = @cust_id
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
        DELETE FROM t_cust
        WHERE cust_id = @cust_id
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

exec p_t_cust 'CREATE'
EXEC p_t_cust 'SEARCH' , null, 'Aiman'
EXEC p_t_cust 'INSERT', 3, 'Aiman', '0123456789', 'mano@example.com', 'LD'
EXEC p_t_cust 'INSERT', 1, 'haroldh', '0113219231', 'harold@example.com', 'sandakan'

EXEC p_t_cust 'UPDATE', 1, 'haroldh32', null, null, 'kk'
EXEC p_t_cust 'DELETE', 3

select * from t_cust


drop table t_cust
exec p_t_state 'INSERT', 'LD', 1

