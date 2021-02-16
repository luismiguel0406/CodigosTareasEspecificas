USE [tl_ctasxpagar]
GO

/****** Object:  View [dbo].[vw_plantilla_impuestos]    Script Date: 2/16/2021 3:18:08 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




ALTER VIEW [dbo].[vw_plantilla_impuestos]
AS
WITH CTE AS
(
	SELECT DI.ti_id																  AS ID
		  ,CASE 
				WHEN DI.ti_tipo_registro = 'FACTURA' THEN FP.fp_id_proveedor
				WHEN DI.ti_tipo_registro = 'GASTO'   THEN RG.rg_proveedor
				ELSE ''
		   END																	  AS COD_PROVEEDOR
		  ,CASE 
				WHEN DI.ti_tipo_registro = 'FACTURA' THEN P.pr_nombre
				WHEN DI.ti_tipo_registro = 'GASTO'   THEN RG.rg_proveedor_nombre
				ELSE ''
		   END																	  AS PROVEEDOR
		  ,CASE 
				WHEN DI.ti_tipo_registro = 'FACTURA' THEN P.pr_rnc
				WHEN DI.ti_tipo_registro = 'GASTO'   THEN RG.rg_identidad
				ELSE ''
		   END																	   AS RNC
		  ,CASE 
				WHEN DI.ti_tipo_registro = 'FACTURA' THEN TBS_F.bs_codigo
				WHEN DI.ti_tipo_registro = 'GASTO'   THEN TBS_R.bs_codigo
				ELSE ''
		   END																	   AS ID_TIPO_BIEN_SERVICIO
		  ,CASE 
				WHEN DI.ti_tipo_registro = 'FACTURA' THEN TBS_F.bs_descripcion
				WHEN DI.ti_tipo_registro = 'GASTO'   THEN TBS_R.bs_descripcion
				ELSE ''
		   END																	   AS TIPO_BIEN_SERVICIO
		  ,CASE 
				WHEN DI.ti_tipo_registro = 'FACTURA' THEN FP.fp_ncf
				WHEN DI.ti_tipo_registro = 'GASTO'   THEN RG.rg_ncf
				ELSE ''
		   END																	   AS NCF
	      ,DI.ti_id_registro													   AS ID_REGISTRO
		  ,DI.ti_tipo_registro													   AS TIPO_REGISTRO
		  ,COALESCE(FP.fp_numero,0)												   AS NUM_DOC
		  ,COALESCE(FP.fp_uni_neg,RG.rg_unid_neg)								   AS UNI_NEG
		  ,COALESCE(FP.fp_fecha_transaccion,RG.rg_fecha_ing)					   AS FECHA_TRANS
		  ,COALESCE(FP.fp_fecha_documento,RG.rg_fecha_gasto)					   AS FECHA_DOC
		  ,COALESCE(FP.fp_fecha_vencimiento,RG.rg_fecha_gasto)					   AS FECHA_VENC
		  ,COALESCE(FP.fp_valor_bruto	,RG.rg_monto)							   AS SUBTOTAL
		  ,COALESCE(FP.fp_itbis			,RG.rg_itbis)							   AS ITBIS
		  ,COALESCE(FP.fp_valor_neto    ,RG.rg_total)							   AS TOTAL
		  ,COALESCE(FP.fp_saldo			,0)										   AS SALDO
		  ,COALESCE(FP.fp_concepto		,RG.rg_concepto_express)				   AS CONCEPTO
		  ,COALESCE(FP.fp_cotizacion	,0)										   AS COTIZACION_US
		  ,COALESCE(FP.fp_nro_entrada	,0)										   AS NUM_ENTRADA
		  ,TI.ti_prefijo														   AS TIPO_IMPUESTO
		  ,DI.ti_valor															   AS VALOR
	   FROM tl_ctasxpagar..tb_detalle_impuesto           DI
	   INNER JOIN tl_ctasxpagar..tb_tipo_impuesto		 TI ON TI.ti_id = DI.ti_tipo_impuesto
	   LEFT JOIN tl_ctasxpagar..cp_facturas_por_pagar    FP ON FP.fp_id = DI.ti_id_registro AND DI.ti_tipo_registro = 'FACTURA'
	   LEFT JOIN tl_ctasxpagar.CCHICA.tb_registro_gastos RG ON RG.rg_id = DI.ti_id_registro AND DI.ti_tipo_registro = 'GASTO'
	   LEFT JOIN tl_ctasxpagar..cp_tipos_bienes_servicios TBS_F ON TBS_F.bs_codigo = FP.fp_id_bienes_serv 
	   LEFT JOIN tl_ctasxpagar..cp_tipos_bienes_servicios TBS_R ON TBS_R.bs_id = RG.rg_tipo_bien_servicios
	   LEFT JOIN tl_ctasxpagar..cp_proveedores P ON P.pr_cod_proveedor =FP.fp_id_proveedor
	   WHERE DI.ti_estado = 1
), CTE_PVT AS 
(
	SELECT ID
		  ,COALESCE(COD_PROVEEDOR,'') AS COD_PROVEEDOR
		  ,COALESCE(PROVEEDOR,'')     AS PROVEEDOR
		  ,RNC
		  ,ID_TIPO_BIEN_SERVICIO
		  ,TIPO_BIEN_SERVICIO
		  ,NCF
		  ,ID_REGISTRO
		  ,TIPO_REGISTRO
		  ,NUM_DOC
		  ,UNI_NEG
		  ,FECHA_TRANS
		  ,FECHA_DOC
		  ,FECHA_VENC
		  ,SUBTOTAL
		  ,ITBIS
		  ,TOTAL
		  ,SALDO
		  ,COALESCE(CONCEPTO,'')      AS CONCEPTO
		  ,COTIZACION_US
		  ,NUM_ENTRADA
		  ,COALESCE([ITFAC],0)        AS ITFAC
		  ,COALESCE([ITLAC],0)        AS ITLAC
		  ,COALESCE([MR]   ,0)        AS MR
		  ,COALESCE([ISR]  ,0)        AS ISR
		  ,COALESCE([ISC]  ,0)        AS ISC
		  ,COALESCE([PL]   ,0)        AS PL
		  ,COALESCE([OT]   ,0)        AS OT
		  --,TIPO_IMPUESTO
		  --,VALOR
	   FROM CTE
	   PIVOT
	   (
			MAX(VALOR) FOR TIPO_IMPUESTO IN ([ITFAC]
										    ,[ITLAC]
											,[MR]
											,[ISR]
											,[ISC]
											,[PL]
											,[OT])
	   ) AS PVT
), FINAL AS 
(
   SELECT CP.ID_REGISTRO
	     ,CP.COD_PROVEEDOR
		 ,CP.PROVEEDOR
		 ,CP.RNC
		 ,CP.ID_TIPO_BIEN_SERVICIO
		 ,CP.TIPO_BIEN_SERVICIO
		 ,CP.NCF
	     ,CP.TIPO_REGISTRO
	     ,CP.NUM_DOC
	     ,CP.UNI_NEG
	     ,CP.FECHA_TRANS
	     ,CP.FECHA_DOC
	     ,CP.FECHA_VENC
	     ,CP.CONCEPTO
	     ,MAX(CP.SUBTOTAL) AS SUBTOTAL
	     ,MAX(CP.ITBIS)    AS ITBIS
	     ,MAX(CP.ITFAC)    AS ITFAC
	     ,MAX(CP.ITLAC)    AS ITLAC
	     ,MAX(CP.MR)       AS MR
	     ,MAX(CP.ISR)      AS ISR
	     ,MAX(CP.ISC)      AS ISC
	     ,MAX(CP.PL)       AS PL
	     ,MAX(CP.OT)       AS OT
	     ,MAX(CP.TOTAL)    AS TOTAL
	     ,MAX(CP.SALDO)    AS SALDO
	     ,CP.COTIZACION_US
	     ,CP.NUM_ENTRADA
      FROM CTE_PVT CP
	  GROUP BY CP.ID_REGISTRO
			  ,CP.COD_PROVEEDOR
			  ,CP.PROVEEDOR
			  ,CP.RNC
			  ,CP.ID_TIPO_BIEN_SERVICIO
			  ,CP.TIPO_BIEN_SERVICIO
			  ,CP.NCF
	          ,CP.TIPO_REGISTRO
	          ,CP.NUM_DOC
	          ,CP.UNI_NEG
	          ,CP.FECHA_TRANS
	          ,CP.FECHA_DOC
	          ,CP.FECHA_VENC
	          ,CP.CONCEPTO
	          ,CP.COTIZACION_US
	          ,CP.NUM_ENTRADA
)
	SELECT F.ID_REGISTRO
	      ,F.COD_PROVEEDOR
		  ,F.PROVEEDOR
		  ,F.RNC	
		  ,F.ID_TIPO_BIEN_SERVICIO
		  ,F.TIPO_BIEN_SERVICIO
		  ,F.NCF
	      ,F.TIPO_REGISTRO
	      ,F.NUM_DOC
	      ,F.UNI_NEG
	      ,F.FECHA_TRANS
	      ,F.FECHA_DOC
	      ,F.FECHA_VENC
	      ,F.CONCEPTO
	      ,F.SUBTOTAL
	      ,F.ITBIS
	      ,F.ITFAC				AS ITBIS_FACTURADO
	      ,F.ITLAC				AS ITBIS_LLEVADO_AL_COSTO
	      ,F.MR					AS MONTO_RETENCION
	      ,F.ISR   
	      ,F.ISC   
	      ,F.PL					AS PROPINA_LEGAL
	      ,F.OT					AS OTROS_TASAS
	      ,F.TOTAL
	      ,F.SALDO
	      ,F.COTIZACION_US
	      ,F.NUM_ENTRADA
	   FROM FINAL F
GO


