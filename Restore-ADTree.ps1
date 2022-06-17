Param (
 $lastKnownRDN,
 $lastKnownParent,
 $identity,
 $partition,
[switch] $includelivechildren,
[switch] $whatIf,
[switch] $verbose
)
 
###############################
##      Display Help         ##
###############################
 
function Display-Help {
""
"Usage:"
""
"Restore-ADTree  -lastKnownRDN "
"[-lastKnownParent ]"
"[-partition ]"
"[-includeLiveChildren]"
"[-whatif]"
"[-verbose]"
"OR"
""
"Restore-ADTree  -identity "
"[-partition ]"
"[-includeLiveChildren]"
"[-whatif]"
"[-verbose]"
""
"Examples:"
""
"Restore-ADTree -lastknownRDN Accounting"
""
"Restore-ADTree -lastKnownRDN Accounting -lastknownParent ""DC=CONTOSO,DC=COM"" "
""
"Restore-ADTree -identity b48290aa-e14f-4417-9c03-560a546d18b9"
""
"Restore-ADTree -identity ""OU=Accounting,DC=CONTOSO,DC=COM"" "
""
}
 
###############################
##     Validate Parameters   ##
###############################
 
if (!(($identity) -or ($lastKnownRDN))){
display-help
break
}
 
if (($identity) -and (($lastKnownRDN) -or ($lastKnownParent))){
display-help
break
}
 
####################################################
##     INCOMPLETE Get RDNType given objClass      ##
####################################################
 
Function Get-RDNType {
Param($objClass)
 
switch ($objClass){
 
"container"{Return "CN"}
"OrganizationalUnit" {Return "OU"}
default {Return "CN"}
}
}
 
############################################
##     Restore-Tree Recursive Function    ##
############################################
 
function Restore-Tree($strObjectGUID ,$strNamingContext, $bIncludeLiveChildren, $bWhatIf ,$strRestoredPrevParentDN)
{
      $objRestoredParent = $null
$objRestoredParent = get-adobject -identity $strObjectGUID -partition $strNamingContext
 
if ($objRestoredParent){
 
if (!($bWhatIf)){
 
Write-Host ""Not restoring live object $objRestoredParent.distinguishedName .""  -ForeGroundColor Yellow
 
} else {
 
Write-Host ""Will not restore live object $objRestoredParent.distinguishedName .""  -ForeGroundColor Yellow
 
}
 
$strLiveSearchBase = $objRestoredParent.distinguishedName
$RestoredDN = $objRestoredParent.distinguishedName
 
} else {
 
if (!($bWhatIf)){
 
Restore-ADobject -identity $strObjectGUID -partition $strNamingContext -errorVariable errRestore
 
if  (($errRestore)){
$objRestoredParent = get-adobject -identity $strObjectGUID -partition $strNamingContext -includeDeletedObjects
Write-Host ""Restore of object $objRestoredParent.distinguishedName failed.`n Error: $errRestore""  -ForeGroundColor Red
Exit Function
} else {
$objRestoredParent = get-adobject -identity $strObjectGUID -partition $strNamingContext
$RestoredDN = $objRestoredParent.distinguishedName
Write-Host ""Successfully restored object $objRestoredParent.DistinguishedName"" -ForeGroundColor Green
}
} else {
$objRestoredParent = get-adobject -identity $strObjectGUID -partition $strNamingContext -properties msds-lastknownRDN,lastKnownParent,whenChanged  -includeDeletedObjects
 
$RestoredDN = $(Get-RDNType($objRestoredParent.ObjectClass)) + "=" + $objRestoredParent.("msds-lastKnownRDN") + "," + $strRestoredPrevParentDN
Write-Host ""Will restore deleted object $RestoredDN""  -ForeGroundColor Green
if ($verbose){
Write-Host ""Deleted DN: $objRestoredParent.distinguishedName `n whenDeleted: $objRestoredParent.("whenChanged") ""
}
}
$strLiveSearchBase = $null
}
 
if (($strLiveSearchBase) -and ($bIncludeLiveChildren)) {
 
$strFilter = "(objectClass=*)"
 
        $objChildren = get-adobject -SearchScope onelevel -SearchBase $strLiveSearchBase -ldapFilter $strFilter  -ResultPageSize 300 -ResultSetSize 10000
 
        if ($objChildren -ne $null){
        foreach ($objChild in $objChildren)
{
Restore-Tree $objChild.objectGUID $strNamingContext $bIncludeLiveChildren $bWhatIf $RestoredDN
}
}
 
}
 
$strSearchBase = "CN=Deleted Objects,"+$strNamingContext
 
$strFilter = "(lastknownParent=" + $objRestoredParent.distinguishedName.Replace("\0","\\0") + ")"
 
        $objChildren = get-adobject -SearchScope subtree -SearchBase $strSearchBase -includedeletedobjects -ldapFilter $strFilter -ResultPageSize 300 -ResultSetSize 10000
 
        if ($objChildren -ne $null){
Write-Host ""Restoring deleted children of $RestoredDN""
        foreach ($objChild in $objChildren)
{
Restore-Tree $objChild.objectGUID $strNamingContext $bIncludeLiveChildren $bWhatIf $RestoredDN
}
}
}
 
######################
##  Main Function   ##
######################
 
$ErrorActionPreference = "SilentlyContinue"
 
if (!($partition)){
$strNamingContext = [string] (get-adrootDSE).defaultNamingContext
} else {
 
$strNamingContext = $partition
}
 
$strDelObjContainer = "CN=Deleted Objects,"+$strNamingContext
 
if ($identity){
 
$objSearchResult = get-adobject -identity $identity -partition $strNamingContext -includeDeletedObjects
 
} else {
 
$strFilter = "(msds-lastknownRDN=" + $lastKnownRDN + ")"
 
$objSearchResult = get-adobject -SearchScope subtree -SearchBase $strDelObjContainer -includedeletedobjects -ldapFilter $strFilter  -properties lastknownparent,whenChanged,isDeleted
}
 
If (!($objSearchResult))  {
Write-Host "Search for tree root returned 0 objects.Exiting without making changes.";Exit
} Else {
 
$objMeasure = $objSearchResult | Measure-Object
If ($objMeasure.Count -gt 1) {
Write-Host "Search for tree root returned more than one object.Rerun command and select one of below objects" -ForeGroundColor Yellow
foreach ($objRoot in $objSearchResult) { $objRoot}
break
}
}
 
if ($objSearchResult.isDeleted) {
 
$PrevParent = $objSearchResult.("lastKnownParent")
$bRootIsDeleted = $true
 
} else {
 
$PrevParent = $objSearchResult.distinguishedName
$bRootIsDeleted = $false
}
 
Restore-Tree $objSearchResult.objectGUID $strNamingContext $includelivechildren $whatIf $PrevParent -errorVariable errRestore