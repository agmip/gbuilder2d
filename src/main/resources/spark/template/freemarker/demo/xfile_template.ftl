*EXP.DETAILS: ${expData['exname']!'????????'}${expData['crid']!'??'} ${expData['local_name']!}

*GENERAL
<#if expData['people']??>
@PEOPLE
 ${expData['people']}
 
</#if>
<#if expData['address']??>
@ADDRESS
 ${expData['address']}
 
</#if>
<#if expData['site_name']??>
@SITE
 ${expData['site_name']}
 
</#if>
<#if expData['exp_narr']??>
@NOTES
 ${expData['exp_narr']} 
 
</#if>
*TREATMENTS                        -------------FACTOR LEVELS------------
@N R O C TNAME.................... CU FL SA IC MP MI MF MR MC MT ME MH SM
<#list treatments as trt>
${trt['trtno']?left_pad(2)} 1 1 0 ${(trt['trt_name']!)?right_pad(25)?substring(0,25)} ${(trt['cuid']!"0")?left_pad(2)} ${(trt['flid']!"0")?left_pad(2)}  0 ${(trt['icid']!"0")?left_pad(2)} ${(trt['plid']!"0")?left_pad(2)} ${(trt['irid']!"0")?left_pad(2)} ${(trt['feid']!"0")?left_pad(2)}  0  0  0  0 ${(trt['haid']!"0")?left_pad(2)} ${(trt['smid']!"0")?left_pad(2)}
</#list>
<#if cultivars?size gt 0>

*CULTIVARS
@C CR INGENO CNAME
</#if>
<#list cultivars as cultivar>
${cultivar?counter?left_pad(2)}${(expData['crid']!-99)?left_pad(3)} ${(cultivar['dssat_cul_id']!(cultivar['cul_id']!-99))?left_pad(6)} ${cultivar['cul_name']!-99}
</#list>
<#if fields?size gt 0>

*FIELDS
@L ID_FIELD WSTA....  FLSA  FLOB  FLDT  FLDD  FLDS  FLST SLTX  SLDP  ID_SOIL    FLNAME
</#if>
<#-- tier 1 -->
<#list fields as field>
${field?counter?left_pad(2)} ${(field['id_field']!-99)?right_pad(8)} <#if field.wst_id_suff??>${(field['wst_id']!)?right_pad(4)}${(field['wst_id_suff']!)?right_pad(4)}<#else>${(field['wst_id']!-99)?right_pad(8)}</#if>   -99   -99 -99     -99   -99 -99   -99    -99  ${(field['soil_id']!-99)?right_pad(10)} ${field['fl_name']!}
</#list>
<#if fields?size gt 0>
@L ...........XCRD ...........YCRD .....ELEV .............AREA .SLEN .FLWR .SLAS FLHST FHDUR
</#if>
<#-- tier 2 -->
<#list fields as field>
${field?counter?left_pad(2)}            -99             -99       -99               -99   -99   -99   -99   -99   -99
</#list>
<#if fields?size gt 0>
@L  BDWD  BDHT PMALB
</#if>
<#-- tier 3 -->
<#list fields as field>
${field?counter?left_pad(2)} ${(field['bdwd']!-99)?left_pad(5)} ${(field['bdht']!-99)?left_pad(5)} ${(field['pmalb']!-99)?left_pad(5)}
</#list>
<#if icDatas?size gt 0>

*INITIAL CONDITIONS
</#if>
<#list icDatas as icData>
@C   PCR ICDAT  ICRT  ICND  ICRN  ICRE  ICWD ICRES ICREN ICREP ICRIP ICRID ICNAME
${icData?counter?left_pad(2)} ${(icData['icpcr_dssat']!-99)?left_pad(5)} ${(icData['icdat']!-99)?left_pad(5)} ${(icData['icrt']!-99)?left_pad(5)} ${(icData['icnd']!-99)?left_pad(5)} ${(icData['icrzc']!-99)?left_pad(5)} ${(icData['icrze']!-99)?left_pad(5)} ${(icData['icwt']!-99)?left_pad(5)} ${(icData['icrag']!-99)?left_pad(5)} ${(icData['icrn']!-99)?left_pad(5)} ${(icData['icrp']!-99)?left_pad(5)} ${(icData['icrip']!-99)?left_pad(5)} ${(icData['icrdp']!-99)?left_pad(5)} ${icData['ic_name']!}
@C  ICBL  SH2O  SNH4  SNO3
<#list icData.soilLayer as layer>
${icData?counter?left_pad(2)} ${(layer['icbl']!-99)?left_pad(5)} ${(layer['ich2o']!-99)?left_pad(5)} ${(layer['icnh4']!-99)?left_pad(5)} ${(layer['icno3']!-99)?left_pad(5)}
</#list>
</#list>
<#if managements.planting?size gt 0>

*PLANTING DETAILS
@P PDATE EDATE  PPOP  PPOE  PLME  PLDS  PLRS  PLRD  PLDP  PLWT  PAGE  PENV  PLPH  SPRL                        PLNAME
</#if>
<#list managements.planting as eventArr>
<#list eventArr as event>
${eventArr?counter?left_pad(2)} ${(event['date']!-99)?left_pad(5)} ${(event['edate']!-99)?left_pad(5)} ${(event['plpop']!-99)?left_pad(5)} ${(event['plpoe']!-99)?left_pad(5)} ${(event['plma']!-99)?left_pad(5)} ${(event['plds']!-99)?left_pad(5)} ${(event['plrs']!-99)?left_pad(5)} ${(event['plrd']!-99)?left_pad(5)} ${(event['pldp']!-99)?left_pad(5)} ${(event['plmwt']!-99)?left_pad(5)} ${(event['page']!-99)?left_pad(5)} ${(event['plenv']!-99)?left_pad(5)} ${(event['plph']!-99)?left_pad(5)} ${(event['plspl']!-99)?left_pad(5)}                        ${event['pl_name']!}--${event.mgn_name!}
</#list>
</#list>
<#if managements.irrigation?size gt 0>

*IRRIGATION AND WATER MANAGEMENT
</#if>
<#list managements.irrigation as eventArr>
@I  EFIR  IDEP  ITHR  IEPT  IOFF  IAME  IAMT IRNAME
${eventArr?counter?left_pad(2)} <#if eventArr[0]??>${(eventArr[0].ireff!-99)?left_pad(5)}</#if>   -99   -99   -99   -99   -99   -99 <#if eventArr[0]??>${eventArr[0].ir_name!-99}--${eventArr[0].full_mgn_name!}</#if>
<#if eventArr[0]?? && eventArr[0].irln??>
@I  IRLN IRSPC IROFS IRDEP
<#list eventArr as event>
<#if event.irln_flg??>
${eventArr?counter?left_pad(2)} ${(event['irln']!-99)?left_pad(5)} ${(event['irspc']!-99)?left_pad(5)} ${(event['irofs']!-99)?left_pad(5)} ${(event['irdep']!-99)?left_pad(5)}
</#if>
</#list>
@I IDATE  IROP IRVAL IRSTR IRDUR  IRLN
<#else>
@I IDATE  IROP IRVAL
</#if>
<#list eventArr as event>
<#if event.irrat??>
${eventArr?counter?left_pad(2)} ${(event['date']!-99)?left_pad(5)} ${(event['irop']!-99)?left_pad(5)} ${(event['irrat']!-99)?left_pad(5)} ${(event['irstr']!-99)?left_pad(5)} ${(event['irdur']!-99)?left_pad(5)} ${(event['irln']!-99)?left_pad(5)}<#if event.mgn_name != event.full_mgn_name>  !${event.ir_name!-99}--${event.mgn_name!}</#if>
<#else>
${eventArr?counter?left_pad(2)} ${(event['date']!-99)?left_pad(5)} ${(event['irop']!-99)?left_pad(5)} ${(event['irval']!-99)?left_pad(5)}<#if event.mgn_name != event.full_mgn_name>                    !${event.ir_name!-99}--${event.mgn_name!}</#if>
</#if>
</#list>
</#list>
<#if managements.fertilizer?size gt 0>

*FERTILIZERS (INORGANIC)
@F FDATE  FMCD  FACD  FDEP  FAMN  FAMP  FAMK  FAMC  FAMO  FOCD FERNAME
</#if>
<#list managements.fertilizer as eventArr>
<#list eventArr as event>
${eventArr?counter?left_pad(2)} ${(event['date']!-99)?left_pad(5)} ${(event['fecd']!-99)?left_pad(5)} ${(event['feacd']!-99)?left_pad(5)} ${(event['fedep']!-99)?left_pad(5)} ${(event['feamn']!0)?left_pad(5)} ${(event['feamp']!0)?left_pad(5)} ${(event['feamk']!0)?left_pad(5)} ${(event['feamc']!0)?left_pad(5)} ${(event['feamo']!0)?left_pad(5)} ${(event['feocd']!0-99)?left_pad(5)} ${event['fe_name']!}--${event.mgn_name!}
</#list>
</#list>
 <#if managements.harvest?size gt 0>

*HARVEST DETAILS
@H HDATE  HSTG  HCOM HSIZE   HPC  HBPC HNAME
</#if>
<#list managements.harvest as eventArr>
<#list eventArr as event>
${eventArr?counter?left_pad(2)} ${(event['date']!-99)?left_pad(5)} ${(event['hastg']!-99)?left_pad(5)} ${(event['hacom']!-99)?left_pad(5)} ${(event['hasiz']!-99)?left_pad(5)} ${(event['happc']!-99)?left_pad(5)} ${(event['habpc']!-99)?left_pad(5)} ${event['ha_name']!}--${event.mgn_name!}
</#list>
</#list>
<#if configs?size gt 0>

*SIMULATION CONTROLS
</#if>
<#list configs as config>
@N GENERAL     NYERS NREPS START SDATE RSEED SNAME.................... SMODEL
${config?counter?left_pad(2)} GE              1     1     S ${(config.general.sdate!-99)?left_pad(5)}  2150 DEFAULT SIMULATION CONTRL 
@N OPTIONS     WATER NITRO SYMBI PHOSP POTAS DISES  CHEM  TILL   CO2
${config?counter?left_pad(2)} OP          ${(config.options.water!"Y")?left_pad(5)} ${(config.options.nitro!"Y")?left_pad(5)}     Y     N     N     N     N     N     M
@N METHODS     WTHER INCON LIGHT EVAPO INFIL PHOTO HYDRO NSWIT MESOM MESEV MESOL
${config?counter?left_pad(2)} ME              M     M     E     R     N     C ${(config.methods.hydro!"R")?left_pad(5)}     1     G     S     2
@N MANAGEMENT  PLANT IRRIG FERTI RESID HARVS
${config?counter?left_pad(2)} MA              R     R     R     R ${(config.management.harvs!"M")?left_pad(5)}
@N OUTPUTS     FNAME OVVEW SUMRY FROPT GROUT CAOUT WAOUT NIOUT MIOUT DIOUT VBOSE CHOUT OPOUT
${config?counter?left_pad(2)} OU              N     Y     Y     1     Y     Y     Y     Y     N     N     D     N     N

@  AUTOMATIC MANAGEMENT
@N PLANTING    PFRST PLAST PH2OL PH2OU PH2OD PSTMX PSTMN
${config?counter?left_pad(2)} PL          82050 82064    40   100    30    40    10
@N IRRIGATION  IMDEP ITHRL ITHRU IROFF IMETH IRAMT IREFF
${config?counter?left_pad(2)} IR             30    50   100 GS000 IR001    10  1.00
@N NITROGEN    NMDEP NMTHR NAMNT NCODE NAOFF
${config?counter?left_pad(2)} NI             30    50    25 FE001 GS000
@N RESIDUES    RIPCN RTIME RIDEP
${config?counter?left_pad(2)} RE            100     1    20
@N HARVEST     HFRST HLAST HPCNP HPCNR
${config?counter?left_pad(2)} HA              0 83057   100     0
 
 </#list>