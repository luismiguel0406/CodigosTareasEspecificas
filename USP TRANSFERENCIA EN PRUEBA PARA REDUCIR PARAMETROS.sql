USE [tl_ctasxpagar]
GO
/****** Object:  StoredProcedure [dbo].[usp_transferencia_express]    Script Date: 2/2/2021 5:15:05 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*********************************************************************************
-------------------------------------------------------------------------------
|Procedure Name:	[CXC].[usp_transferencia_express]
|Created Date:      15/12/2020
|Author:         	Luis Del orbe               	
|Ticket Num: 
|
|Description:                                                   
|
|Modification Log:
=================================================================================
| Date        |Developer 			|Ticket No.        |Description
=================================================================================
|15/12/2020   |Luis Del orbe       	|				   |Version Initial
*********************************************************************************/

ALTER PROCEDURE [dbo].[usp_transferencia_express]

--PARAMETROS--

	 @NUMQUERY          INT 
	,@XML               XML         = NULL -- XML PARA EL PRIMER NUMQUERY
	,@DETALLES_XML      XML         = NULL
	--,@JSON				NVARCHAR(MAX) = NULL
	--,@ID_MOVIMIENTO		INT         = NULL OUTPUT
    --PARAMETROS PARA LOS DEMAS NUMQUERY
	--,@ID_DETALLE        INT         = NULL 
	--,@CUENTA            VARCHAR(20) = NULL
	--,@BENEFICIARIO      VARCHAR(100)= NULL  
	--,@DESDE_MONTO       MONEY       = NULL
	--,@HASTA_MONTO       MONEY       = NULL
	--,@DESDE_FECHA       VARCHAR(50) = NULL
	--,@HASTA_FECHA       VARCHAR(50) = NULL
	,@SECUENCIA_CONTABLE INT = NULL OUTPUT
AS
 BEGIN

 --DECLARO LAS VARIABLES A UTILIZAR--
  BEGIN TRAN
  
      DECLARE

				@ID_MOVIMIENTO      INT = NULL 
			   ,@TIPO_CTA           VARCHAR(15),--RECIBIR DESDE LA TABLA CUENTA BANCO O SOLAMENTE INDICAR C, QUE ES LA CUENTA EN PESOS
				@MES                TINYINT,
				@ANIO               SMALLINT, 
				@ID_BANCO           INT,
				@ID_CTA_BANCO       INT,
				@DESCRIPCION        VARCHAR(100),
				@ID_REFERENCIA      VARCHAR(5),
				@MONEDA             SMALLINT,
				@W_MVALOR_BASE      MONEY,
				@LINEA              INT = 0,
				@DEBITO             MONEY,
				@CREDITO            MONEY,
				@DEBITO_BSE         MONEY,
				@CREDITO_BSE        MONEY,
				@cuenta_con         varchar(25),
				@ERROR              INT,
			    @UNIDAD_NEGOCIO	    VARCHAR(10),
			    @CTA_BANCO	        VARCHAR(20),
				@FECHA  		    DATETIME,
				@MONTO				MONEY,
				@ID_OPERACION		VARCHAR(1),
				@TIPO_MOVIMIENTO	INT,
				@TIPO_TRATAMIENTO	VARCHAR(5),
				@CONCEPTO			VARCHAR(MAX),
				@SECUENCIA_CONT     INT,
				@MONEDA_CTA         INT,
				@NUMPAGO            INT,
				@ID_PROVEEDOR       INT,         
				@ID_DETALLE         INT,          
				
				@BENEFICIARIO       VARCHAR(100), 
				@DESDE_MONTO        MONEY,       
			    @HASTA_MONTO        MONEY,       
				@DESDE_FECHA        VARCHAR(50), 
				@HASTA_FECHA        VARCHAR(50), 
					
				@COTIZACION		    MONEY,
				@USUARIO			VARCHAR(15),
				@TERMINAL			VARCHAR(15),
				@MENSAJE            VARCHAR(50),
				@SECUENCIA_DOC      INT
				
				
				--@CUENTA_GASTO       VARCHAR(20),
				--@VALOR_GASTO        MONEY,
				--@TIPO_TRANS         INT
				 


			
--********************************************************--
--************TOMO LOS VALORES DEL LOS XML****************--
--********************************************************--

	           SELECT 
			   @CTA_BANCO =         T.COL.query('./CuentaBanco')    .value('.','VARCHAR(100)'),
			   @FECHA =             T.COL.query('./Fecha')          .value('.','DATETIME'),
		       @MONTO =             T.COL.query('./Monto')          .value('.','MONEY'),
			   @ID_OPERACION =      T.COL.query('./Id_Operacion')   .value('.','VARCHAR(100)'),
			   @TIPO_MOVIMIENTO =   T.COL.query('./TipoMovimiento') .value('.','INT'),
			   @TIPO_TRATAMIENTO =  T.COL.query('./TipoTratamiento').value('.','VARCHAR(100)'),
			   @CONCEPTO =          T.COL.query('./Concepto')       .value('.','VARCHAR(100)'),
			   @BENEFICIARIO =      T.COL.query('./Beneficiario')   .value('.','VARCHAR(100)'),
			   @COTIZACION =        T.COL.query('./CotizacionDolar').value('.','MONEY'),
			   @USUARIO =           T.COL.query('./Usuario')        .value('.','VARCHAR(100)'),
			   @TERMINAL =          T.COL.query('./Terminal')       .value('.','VARCHAR(100)')
			 
			/*   @ID_PROVEEDOR =      T.COL.query('./IdProveedor')    .value('.','INT'),
			   @ID_DETALLE =        T.COL.query('./Id_Detalle')     .value('.','INT'),
			   @DESDE_MONTO =       T.COL.query('./desdeMonto')     .value('.','MONEY'),
			   @HASTA_MONTO =       T.COL.query('./hastaMonto')     .value('.','MONEY'),
			   @DESDE_FECHA =       T.COL.query('./desdeFecha')     .value('.','VARCHAR(100)'),
			   @HASTA_FECHA =       T.COL.query('./hastaFecha')     .value('.','VARCHAR(100)')*/
			   
		       FROM @XML.nodes('./Root') AS T(COL)
		
--********************************************************--
--******************** SET DE VARIABLES ******************--
--*******************************************************--

			SET @MES           = MONTH(@FECHA)
			SET @ANIO          = YEAR(@FECHA)

			SET @W_MVALOR_BASE = ROUND((@MONTO / @COTIZACION),2)
			--SET @MONEDA        = 1 -- EL UNO SIGNIFICA PESOS
			SET @DESCRIPCION   = 'TRANSACCION CUENTA: '+ @CTA_BANCO
			SET @ERROR         = 0

--********************************************************--
--************OBTENGO LOS DATOS DE LA CUENTA *************--
--********************************************************--

			SELECT @ID_BANCO			= cu_banco_id,
				   @ID_CTA_BANCO		= cu_cuenta_id,
				   @UNIDAD_NEGOCIO		= cu_uni_neg,
				   @TIPO_CTA			= cu_tipo_cuenta,
				   @cuenta_con			= cu_cuenta,
				   @MONEDA_CTA			= cu_moneda
			FROM   cp_cuenta_banco
			WHERE  cu_cta_banco			 = @CTA_BANCO
		    AND    cu_estado			 = 'A'

		    SELECT @ID_REFERENCIA        = ti_id_ref
			FROM   cp_tipo_mov_cuenta 
			WHERE  ti_id                 = @TIPO_MOVIMIENTO


--********************************************************--
--********INSERTO EL HEADER DE LA TRANSFERENCIA***********--
--********************************************************--
	
			 			   
 IF (@NUMQUERY = 1)		   
  BEGIN
					
			INSERT INTO tl_ctasxpagar.[dbo].[cp_mov_cuenta]
			( 
				 mc_fec_tra			,mc_anio				,mc_mes					,mc_tipo_id				,mc_id_ref			
				,mc_tipo_operacion	,mc_tipo_tratamiento	,mc_origen				,mc_genera_cheque		,mc_genera_con		
				,mc_banco_id		,mc_cuenta_id			,mc_tipo_cta			,mc_cta_banco			,mc_moneda			
				,mc_cotizacion		,mc_valor				,mc_valor_bse			,mc_desc_corta			,mc_descripcion		
				,mc_id_cheque		,mc_beneficiario		,mc_fecha_con			,mc_unidad_negocio_con  ,mc_estado				
				,mc_usuario			,mc_terminal		    ,mc_fecha_act  

			)
			VALUES
			(
				@FECHA              ,@ANIO                  ,@MES                    ,@TIPO_MOVIMIENTO       ,@ID_REFERENCIA
			   ,@ID_OPERACION       ,@TIPO_TRATAMIENTO      ,'CXP'                   ,0                      ,0
			   ,@ID_BANCO           ,@ID_CTA_BANCO          ,@TIPO_CTA               ,@CTA_BANCO             ,@MONEDA_CTA
			   ,@COTIZACION         ,@MONTO                 ,@W_MVALOR_BASE          ,@DESCRIPCION           ,@CONCEPTO
			   ,NULL                ,@BENEFICIARIO          ,@FECHA                  ,@UNIDAD_NEGOCIO        ,1                      
			   ,@USUARIO            ,@TERMINAL              ,@FECHA
			)
			
	
			IF (@@ERROR = 0)
				BEGIN
					SELECT @ID_MOVIMIENTO = @@IDENTITY
				END

	IF (@TIPO_TRATAMIENTO = 'NOR')
			BEGIN
				SET @LINEA = @LINEA + 1

				IF (@ID_OPERACION = 'D') --debitar a la cuenta-banco (movimiento contable es en el credito)
					BEGIN
						SET @DEBITO = 0
						SET @CREDITO = @MONTO
			
						SET @DEBITO_BSE = 0
						SET @CREDITO_BSE = @W_MVALOR_BASE						
					END	

	/*		   IF (@ID_OPERACION = 'C') --acreditar a la cuenta-banco (movimiento contable es en el debito)
					BEGIN
						SET @DEBITO     = @MONTO 
						SET @CREDITO    = 0
	      
						SET @DEBITO_BSE  = @W_MVALOR_BASE      
						SET @CREDITO_BSE = 0
					END		
	
	*/		  
	END

		INSERT INTO cp_det_mov_cuenta 
		(
			 cc_id_movimiento    ,cc_linea		,cc_operacion				,cc_unidad_negocio      ,cc_cuenta		
			,cc_debito			 ,cc_credito	,cc_debito_bse				,cc_credito_bse			,cc_usuario     
			,cc_fec_act			 ,cc_estado		,cc_ffecha_transaccion		,cc_terminal			,cc_descripcion
		)	   
		VALUES 
		(
			 @ID_MOVIMIENTO		 ,@LINEA		,@ID_OPERACION				,@UNIDAD_NEGOCIO		,@cuenta_con
			,@DEBITO			 ,@CREDITO		,@DEBITO_BSE				,@CREDITO_BSE			,@USUARIO
			,@FECHA				 ,1             ,@FECHA					    ,@TERMINAL				,@DESCRIPCION
		)
	
	IF (@ID_OPERACION = 'D')
		BEGIN 
			SET @ID_OPERACION = 'C'
		END

--********************************************************--
--**TABLA TEMPORAL PARA RECIBIR LA LISTA DE LOS DETALLES**--
--********************************************************--


	IF(OBJECT_ID('tempdb..#DETALLE_TRANS') IS NOT NULL)
					DROP TABLE #DETALLE_TRANS	


 CREATE TABLE #DETALLE_TRANS
  (
  ID               INT PRIMARY KEY IDENTITY (1,1),
  LINEA            INT,
  CUENTA_GASTO     NVARCHAR(30),
  DESCRIPCION      NVARCHAR(50),
  DEBITO           MONEY,
  CREDITO          MONEY,
  DEBITO_BSE       MONEY,
  CREDITO_BSE      MONEY
   
  )
   
  INSERT INTO #DETALLE_TRANS  (LINEA, CUENTA_GASTO, DESCRIPCION, DEBITO, CREDITO, DEBITO_BSE, CREDITO_BSE)
  SELECT 
  
     T.COL.query('./Linea')       .value('.','INT'),
	 T.COL.query('./CuentaGasto') .value('.','VARCHAR(100)'),
	 T.COL.query('./descripcion') .value('.','VARCHAR(100)'),
	 T.COL.query('./debito')      .value('.','MONEY'),
	 T.COL.query('./credito')     .value('.','MONEY'),
	 T.COL.query('./debitoBse')   .value('.','MONEY'),
	 T.COL.query('./creditoBse')  .value('.','MONEY')
	  	 	 
    FROM @DETALLES_XML.nodes('./Root/detalleTransferencia') AS T(COL)

--***********************************************************--
--*********INSERTO LOS VALORES DE LA TABLA TEMPORAL**********--
--***********************************************************--
	
 
	INSERT	INTO cp_det_mov_cuenta 
	(
	 cc_id_movimiento    ,cc_linea		,cc_operacion				,cc_unidad_negocio      ,cc_cuenta		
	,cc_debito			 ,cc_credito	,cc_debito_bse				,cc_credito_bse			,cc_usuario     
	,cc_fec_act			 ,cc_estado		,cc_ffecha_transaccion		,cc_terminal			,cc_descripcion
		
	)
	SELECT 
	 @ID_MOVIMIENTO     ,D.LINEA        ,@ID_OPERACION              ,@UNIDAD_NEGOCIO        ,D.CUENTA_GASTO
	,D.DEBITO           ,D.CREDITO      ,D.DEBITO_BSE               ,D.CREDITO_BSE          ,@USUARIO
	,@FECHA             ,1              ,@FECHA                     ,@TERMINAL              ,D.DESCRIPCION
	
	FROM #DETALLE_TRANS D
   


--***********************************************************--
--**************OBTENGO LA SECUENCIA CONTABLE****************--
--***********************************************************--

	EXEC [Administracion].[dbo].[sp_cseqnos]
					@i_filial		= 1,
					@i_oficina		= 1,
					@i_tabla		= 'co_hdr_diario',
					@i_pkey			= '16',
					@t_debug		= 'N',
					@o_siguiente	= @SECUENCIA_CONT OUTPUT,
					@o_return		= @ERROR	   OUTPUT,
					@t_from			= 'sp_pro_contab_proc03'

		IF @error <> 0
			BEGIN
				SET @mensaje = 'Error al obtener la secuencia del comprobante'
					ROLLBACK TRAN
					RAISERROR(@mensaje ,16 ,1) WITH NOWAIT		  
				RETURN 1      
			END

--***********************************************************--
--***********OBTENGO LA SECUENCIA DEL DOCUMENTO**************--
--***********************************************************--

	EXECUTE [tl_ctasxpagar].[dbo].[usp_get_secuencia_documento] 
				    @p_tipo_comprobante = 16
				  , @unidad_negocio     = @UNIDAD_NEGOCIO
				  , @usuario			= @USUARIO		  
				  , @terminal		    = @TERMINAL
				  , @sec_documento	    = @SECUENCIA_DOC OUTPUT


--***********************************************************--
--***************INSERTO A DIARIO GENERAL********************--
--***********************************************************--

		INSERT INTO tl_contabilidad..co_hdr_diario 
			(
					 hd_filial			,hd_uni_neg				,hd_tipo				,hd_seq						,hd_ano           
					,hd_mes             ,hd_fecha_ing			,hd_fecha_con			,hd_fecha_ult_mod			,hd_fecha_ult_dma 
					,hd_glosa			,hd_total_debito		,hd_total_credito		,hd_total_debito_bse		,hd_total_credito_bse 
					,hd_moneda			,hd_moneda_bse			,hd_cotizacion			,hd_cliente					,hd_proveedor    
					,hd_origen			,hd_uni_ref				,hd_id_ref				,hd_estado					,hd_seq_doc       
					,hd_error			,hd_fecha_error			,hd_operador			,hd_filial_aud				,hd_oficina           
					,hd_terminal        ,hd_fecha_act
			)				
			VALUES(
			       1                  ,@UNIDAD_NEGOCIO          ,'16'                   ,@SECUENCIA_CONT            ,@ANIO
				   ,@MES              ,@FECHA                   ,@FECHA                 ,@FECHA                     ,@FECHA
				   ,@CONCEPTO         ,@MONTO                   ,@MONTO                 ,@W_MVALOR_BASE             ,@W_MVALOR_BASE
				   ,1                 ,2                        ,@COTIZACION            ,0                          ,0
				   ,'CXP'             ,NULL                     ,0                      ,'A'                        ,@SECUENCIA_DOC
				   ,'N'               ,NULL                     ,@USUARIO               ,1                          ,1
				   ,@TERMINAL         ,@FECHA    
		
			)

       IF @@ERROR <> 0
			BEGIN		
				SET @error = 16		
				SET @mensaje = 'Error al insertar en co_hdr_diario en sp_pro_contab_proc05'
				RAISERROR(@mensaje ,@error ,1) WITH NOWAIT								
			END				  
		ELSE
			BEGIN		
				SELECT @SECUENCIA_CONTABLE = @SECUENCIA_CONT
			END

--***********************************************************--
--***********INSERTO A DETALLE DIARIO GENERAL****************--
--***********************************************************--

         INSERT INTO tl_contabilidad..co_det_diario 
			(
				 de_filial				,de_uni_neg					,de_tipo					,de_seq						,de_linea_num      
				,de_ano				    ,de_mes						,de_cuenta					,de_dpto					,de_producto      
				,de_proyecto			,de_openitem				,de_debito					,de_credito					,de_debito_bse      
				,de_credito_bse		    ,de_glosa					,de_fecha_ing				,de_fecha_con				,de_estado    
				,de_seq_doc			    ,de_seq_int					,de_operador				,de_filial_aud				,de_oficina       
				,de_terminal			,de_fecha_act
			)
			SELECT 
			     1                      ,@UNIDAD_NEGOCIO             ,'16'                      ,@SECUENCIA_CONT            ,DT.cc_linea
				,@ANIO                  ,@MES                        ,DT.cc_cuenta              , '-'                       ,'-'
				,'-'                    ,'-'                         ,DT.cc_debito              ,DT.cc_credito              ,DT.cc_debito_bse
				,DT.cc_credito_bse      ,DT.cc_descripcion           ,@FECHA                    ,@FECHA                     ,'A'
				,@SECUENCIA_DOC         ,null                        ,@USUARIO                  ,1                          ,1
				,@TERMINAL              ,@FECHA 
					
			FROM cp_det_mov_cuenta DT WHERE DT.cc_linea >=1
		    AND DT.[cc_id_movimiento]  = @ID_MOVIMIENTO
			

         IF @@ERROR <> 0
			BEGIN	
				SET @error = 16					
				SET @mensaje = 'Error al insertar en co_hdr_diario en sp_pro_contab_proc05'
				RAISERROR(@mensaje ,@error ,1) WITH NOWAIT								
			END      

--***********************************************************--
--****************ACTUALIZO TIPO COMPROBANTE ****************--
--***********************************************************--
           UPDATE cp_mov_cuenta 
				SET	
					 mc_genera_con			 = 1
					,[mc_tipo_comprobante]	 = '16'
			   	    ,mc_secm_con			 = @SECUENCIA_CONT
			WHERE mc_id      = @ID_MOVIMIENTO			  
		    AND mc_estado  = 1

		 /*	
		 UPDATE [cp_cheques]
				SET [ch_num_cheque] = @SECUENCIA_DOC
			FROM [cp_mov_cuenta]
			INNER JOIN cp_cheques ON [ch_id] = [mc_id_cheque]
			WHERE mc_id = @id_movimiento
          */
			IF (@@ERROR = 0)
				BEGIN
				   
					SELECT @mensaje = 'EL REGISTRO DE LA CUENTA DE GASTOS SE REALIZO CORRECTAMENTE'
					
				END
END

--1/2/2021 luis del orbe EN PROCESO
--********************************************************************************************************************--
--********************** INSERTO LOS VALORES DE LA TRANSFERENCIA EN LOS PAGOS REALIZADOS******************************--
--********************************************************************************************************************--
/*
			INSERT INTO tl_ctasxpagar.dbo.cp_pagos(

			     pg_uni_neg			,pg_id_proveedor		,pg_fecha			,pg_forma_pago			,pg_id_banco			
				,pg_moneda_cta		,pg_tipo_cta_banco		,pg_cta_banco		,pg_id_chequera			,pg_serie_cheque    		
				,pg_moneda			,pg_cotizacion			,pg_valor			,pg_valor_bse   		,pg_fecha_contable     	
				,pg_estado			,pg_usuario				,pg_terminal		,pg_fecha_act			,pg_id_cta_banco
				,pg_tipo_comprobante

			)
				VALUES (
				@UNIDAD_NEGOCIO      ,@ID_PROVEEDOR          ,@FECHA             ,'TRF'                  ,@ID_BANCO
			   ,@MONEDA_CTA          ,@TIPO_CTA              ,@CTA_BANCO         , 0/*ID CHEQUERA*/      ,0--SERIE CHEQUE  
			   ,@MONEDA              ,@COTIZACION            ,@MONTO             ,@W_MVALOR_BASE         ,@FECHA
			   ,1                    ,@USUARIO               ,@TERMINAL          ,@FECHA                 ,@ID_CTA_BANCO
			   ,'-'

			)

			SELECT @NUMPAGO = @@IDENTITY

			INSERT INTO [tl_ctasxpagar].[dbo].[cp_det_pagos]
         (
		    [dp_num_pago]		,[dp_id_documento]			,[dp_valor_aplicado]		,[dp_valor_aplicado_bse]
           ,[dp_estado]			,[dp_fecha_actualizacion]	,[dp_fecha_contable]        ,[dp_moneda]
		 )
		VALUES
        (
		    @numpago			,123456			         	,@MONTO						,@W_MVALOR_BASE
           ,1				    ,@fecha						,@FECHA                     ,@MONEDA_CTA
		)

*/
--*************************************************************************************************************************--
--*************************************************************************************************************************--

  IF (@NUMQUERY = 2)--OBTENGO TODAS LAS TRANSFERENCIAS
		BEGIN
				SELECT MC.mc_id    AS Id, 
				MC.mc_secm_con     AS Secuencia, 
				MC.mc_fec_tra      AS Fecha_Transf, 
				MC.mc_cta_banco    AS Cuenta,
				MC.mc_valor        AS Valor, 
				MC.mc_descripcion  AS Descripcion,
				MC.mc_beneficiario AS Beneficiario, 
				MC.mc_fecha_con    AS Fecha_Cont 
				FROM tl_ctasxpagar.dbo.cp_mov_cuenta MC 
				WHERE MC.mc_id_ref = 'DTR'
				AND MC.mc_estado = 1
				order by MC.mc_id desc;
		END


  IF (@NUMQUERY = 3) --OBTENGO LAS TRANSFERENCIAS POR FILTRO SELECCIONADO(FECHA, MONTO, CUENTA O BENEFICIARIO)
			BEGIN


				  SELECT MC.mc_id            AS Id, 
						 MC.mc_secm_con      AS Secuencia, 
						 MC.mc_fec_tra       AS Fecha_Transf, 
						 MC.mc_cta_banco     AS Cuenta,
						 MC.mc_valor         AS Valor, 
						 MC.mc_descripcion   AS Descripcion,
						 MC.mc_beneficiario  AS Beneficiario, 
						 MC.mc_fecha_con     AS Fecha_Cont 
					FROM tl_ctasxpagar.dbo.cp_mov_cuenta MC
					WHERE MC.mc_id_ref = 'DTR' 
					AND MC.mc_estado = 1 
					AND ((CAST(MC.mc_fec_tra AS DATE) BETWEEN CAST(@DESDE_FECHA AS DATE) AND CAST(@HASTA_FECHA AS DATE)) OR @DESDE_FECHA IS NULL)
					AND ((MC.mc_cta_banco LIKE '%' + @CTA_BANCO + '%') OR @CTA_BANCO IS NULL)
					AND ((MC.mc_beneficiario LIKE '%' + @BENEFICIARIO + '%') OR @BENEFICIARIO IS NULL)
					AND ((MC.mc_valor BETWEEN @DESDE_MONTO AND @HASTA_MONTO) OR @DESDE_MONTO IS NULL)
					ORDER BY MC.mc_id DESC;
					--SELECT @XML OUTPUT	
			END

	IF (@NUMQUERY = 4) -- MANIPULACION DE TRANSFERENCIA 

			BEGIN
				IF (NOT EXISTS (	
				SELECT * 
				FROM tl_ctasxpagar.dbo.cp_mov_cuenta MC 
				WHERE MC.mc_id =  @ID_DETALLE
				AND MC.mc_estado = 1 ))
			BEGIN
					PRINT 'Exito';
			END
	 ELSE
			BEGIN

				SELECT @SECUENCIA_CONT = MC.mc_secm_con
				      ,@UNIDAD_NEGOCIO = MC.mc_unidad_negocio_con
					FROM tl_ctasxpagar.dbo.cp_mov_cuenta MC 
					WHERE MC.mc_id     =  @ID_DETALLE
					order by MC.mc_id desc;

				-- ======================== --
				-- ===== ANULO TRANSF ===== --
				-- ======================== --
		UPDATE M
	    SET M.mc_estado           =      0
		FROM tl_ctasxpagar.[dbo].[cp_mov_cuenta] M
		WHERE  M.mc_id            = @ID_DETALLE 

		UPDATE DT
	    SET    DT.cc_estado       =      0
		FROM   tl_ctasxpagar.[dbo].[cp_det_mov_cuenta] DT
		WHERE  DT.cc_id_movimiento= @ID_DETALLE

				-- ========================= --
				-- ===== ANULO ENTRADA ===== --
				-- ========================== --

	   UPDATE AE
       SET AE.[ae_estado]          = 0 
          ,AE.[ae_estado_reg]      = 'X'
	   FROM [tl_contabilidad].[dbo].[co_aprobaciones_anulacion_entradas] AE
       WHERE AE.ae_num_entrada     = @SECUENCIA_CONT
       AND AE.ae_tipo_documento    = '16'
       AND AE.ae_uni_neg           = @UNIDAD_NEGOCIO 
    
		UPDATE H  
		SET H.hd_estado            = 'X'
		   ,H.hd_fecha_anulacion   = GETDATE()
		   ,H.hd_usuario_anulo     = @USUARIO
		    from tl_contabilidad..co_hdr_diario H
		    WHERE H.hd_seq         = @SECUENCIA_CONT
		    AND H.hd_tipo          = '16'
		    AND H.hd_uni_neg       = @UNIDAD_NEGOCIO
    
		UPDATE D  
		   SET D.de_estado         = 'X'
		   FROM tl_contabilidad..co_det_diario D
		   WHERE D.de_seq          = @SECUENCIA_CONT
		   AND D.de_tipo           = '16'
		   AND D.de_uni_neg        = @UNIDAD_NEGOCIO

 

     -- Insertando en el log de entradas anuladas..
    INSERT INTO [tl_contabilidad].[dbo].[co_log_anulacion]
    (
        [la_filial],        [la_uni_neg],         [la_tipo],            [la_seq],
        [la_app],            [la_login],          [la_fecha],        [la_terminal]
    )
    VALUES
    (
        1,                               @UNIDAD_NEGOCIO,       '16',            @SECUENCIA_CONT,
        'HUNTER CONTABILIDAD',           @USUARIO,           GETDATE(),          @TERMINAL
    )


			END
		END

		
		
		
		IF @@ERROR = 0
			BEGIN 
				COMMIT TRAN 		 
			END
		ELSE
			BEGIN 
			    ROLLBACK
			END
	
	END
