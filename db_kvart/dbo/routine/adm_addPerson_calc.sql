CREATE   PROCEDURE [dbo].[adm_addPerson_calc]
(
	@Status_id1		VARCHAR(10) -- код статуса прописки
	,@service_id1	VARCHAR(10)  -- код услуги
	,@paym			BIT                      -- 1 -начислять на услугу;     0 - нет
)
AS
	--
	--
	--
	SET NOCOUNT ON

	IF EXISTS (SELECT
				*
			FROM dbo.Person_calc
			WHERE status_id = @Status_id1
			AND service_id = @service_id1)
	BEGIN
		UPDATE dbo.PERSON_CALC
		SET have_paym = @paym
		WHERE status_id = @Status_id1
		AND service_id = @service_id1
	END
	ELSE
	BEGIN
		INSERT
		INTO dbo.Person_calc
		(	status_id
			,service_id
			,have_paym)
		VALUES (@Status_id1
				,@service_id1
				,@paym)
	END

	SET NOCOUNT ON
go

