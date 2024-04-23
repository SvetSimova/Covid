/*

Cleaning Data in SQL Queries

*/


Select *
From NashHouse.dbo.NHouse

---------------------------------------------------------------------


-- 1. Standardize Date Format


Select SaleDate, CONVERT(Date, SaleDate)
From NashHouse.dbo.NHouse


Update NHouse
SET SaleDate = CONVERT(Date, SaleDate)

-- If it doesn't Update properly

ALTER TABLE NHouse
Add SaleDateConverted Date;

Update NHouse
SET SaleDateConverted = CONVERT(Date,SaleDate);

-- Checking the result

Select SaleDateConverted, CONVERT(Date, SaleDate)
From NashHouse.dbo.NHouse

-- !!! SaleDate to drop later

-------------------------------------------------------------------------

-- 2. Populate Property Address data

Select *
From NashHouse.dbo.NHouse
--Where PropertyAddress is null
order by ParcelID


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, 
	ISNULL(a.PropertyAddress,b.PropertyAddress)
From NashHouse.dbo.NHouse a
JOIN NashHouse.dbo.NHouse b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From NashHouse.dbo.NHouse a
JOIN NashHouse.dbo.NHouse b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

-- Checking the result 

Select *
From NashHouse.dbo.NHouse
Where PropertyAddress is null
order by ParcelID
-- must be zero rows

-- !!! PropertyAddress to drop later

-----------------------------------------------------------------------------

-- 3. Breaking out Address into Individual Columns (Address, City, State)


Select PropertyAddress
From NashHouse.dbo.NHouse


-- STRING way for PropertyAddress

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address
From NashHouse.dbo.NHouse


ALTER TABLE NHouse
Add PropertySplitAddress Nvarchar(255);

Update NHouse
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)


ALTER TABLE NHouse
Add PropertySplitCity Nvarchar(255);

Update NHouse
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

Select *
From NashHouse.dbo.NHouse


-- PARSE way for OwnerAddress

Select OwnerAddress
From NashHouse.dbo.NHouse


Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From NashHouse.dbo.NHouse



ALTER TABLE NHouse
Add OwnerSplitAddress Nvarchar(255);

Update NHouse
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE NHouse
Add OwnerSplitCity Nvarchar(255);

Update NHouse
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE NHouse
Add OwnerSplitState Nvarchar(255);

Update NHouse
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


Select *
From NashHouse.dbo.NHouse

-- !!! OwnerAddress to drop later

----------------------------------------------------------------------------

-- 4. Change Y and N to Yes and No in "Sold as Vacant" field


Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From NashHouse.dbo.NHouse
Group by SoldAsVacant
order by 2


Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From NashHouse.dbo.NHouse


Update NHouse
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

-- the other way
-- SET SoldAsVacant = REPLACE(REPLACE(SoldAsVacant, 'Y', 'Yes'), 'N', 'No')

-------------------------------------------------------------------------------

-- 5. Remove Duplicates

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					ORDER BY
					UniqueID
					) row_num

From NashHouse.dbo.NHouse
--order by ParcelID -- to check the correctness of the subquery
)
Select * 
From RowNumCTE
Where row_num > 1
Order by PropertyAddress


-- Removing

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					ORDER BY
					UniqueID
					) row_num

From NashHouse.dbo.NHouse
)
DELETE
From RowNumCTE
Where row_num > 1


Select *
From NashHouse.dbo.NHouse


---------------------------------------------------------------------------

-- 6. Delete Unused Columns


Select *
From NashHouse.dbo.NHouse


ALTER TABLE NashHouse.dbo.NHouse
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate