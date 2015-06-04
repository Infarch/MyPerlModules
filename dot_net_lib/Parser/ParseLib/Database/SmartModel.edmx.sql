
-- --------------------------------------------------
-- Entity Designer DDL Script for SQL Server 2005, 2008, and Azure
-- --------------------------------------------------
-- Date Created: 01/03/2013 14:24:20
-- Generated from EDMX file: C:\Users\sku\Documents\Visual Studio 2010\Projects\Parser\ParseLib\Database\SmartModel.edmx
-- --------------------------------------------------

SET QUOTED_IDENTIFIER OFF;
GO
USE [SmartParser];
GO
IF SCHEMA_ID(N'dbo') IS NULL EXECUTE(N'CREATE SCHEMA [dbo]');
GO

-- --------------------------------------------------
-- Dropping existing FOREIGN KEY constraints
-- --------------------------------------------------

IF OBJECT_ID(N'[dbo].[FK_BrandDescription]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[Descriptions] DROP CONSTRAINT [FK_BrandDescription];
GO
IF OBJECT_ID(N'[dbo].[FK_ProductDescription]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[Descriptions] DROP CONSTRAINT [FK_ProductDescription];
GO
IF OBJECT_ID(N'[dbo].[FK_CategoryDescription]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[Descriptions] DROP CONSTRAINT [FK_CategoryDescription];
GO
IF OBJECT_ID(N'[dbo].[FK_ProductCategory]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[WebResourceSet_Product] DROP CONSTRAINT [FK_ProductCategory];
GO
IF OBJECT_ID(N'[dbo].[FK_ProductBrand]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[WebResourceSet_Product] DROP CONSTRAINT [FK_ProductBrand];
GO
IF OBJECT_ID(N'[dbo].[FK_CategoryCategory]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[WebResourceSet_Category] DROP CONSTRAINT [FK_CategoryCategory];
GO
IF OBJECT_ID(N'[dbo].[FK_FeatureFeatureGroup]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[Features] DROP CONSTRAINT [FK_FeatureFeatureGroup];
GO
IF OBJECT_ID(N'[dbo].[FK_FeatureValueFeature]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[FeatureValues] DROP CONSTRAINT [FK_FeatureValueFeature];
GO
IF OBJECT_ID(N'[dbo].[FK_FeatureValueProduct]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[FeatureValues] DROP CONSTRAINT [FK_FeatureValueProduct];
GO
IF OBJECT_ID(N'[dbo].[FK_DescriptionFileDescription]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[DescriptionFiles] DROP CONSTRAINT [FK_DescriptionFileDescription];
GO
IF OBJECT_ID(N'[dbo].[FK_DescriptionFileFile]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[DescriptionFiles] DROP CONSTRAINT [FK_DescriptionFileFile];
GO
IF OBJECT_ID(N'[dbo].[FK_BrandFile]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[WebResourceSet_Brand] DROP CONSTRAINT [FK_BrandFile];
GO
IF OBJECT_ID(N'[dbo].[FK_CategoryFile]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[WebResourceSet_Category] DROP CONSTRAINT [FK_CategoryFile];
GO
IF OBJECT_ID(N'[dbo].[FK_ProductFileProduct]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[ProductFiles] DROP CONSTRAINT [FK_ProductFileProduct];
GO
IF OBJECT_ID(N'[dbo].[FK_ProductFileFile]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[ProductFiles] DROP CONSTRAINT [FK_ProductFileFile];
GO
IF OBJECT_ID(N'[dbo].[FK_WebPage_inherits_WebResource]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[WebResourceSet_WebPage] DROP CONSTRAINT [FK_WebPage_inherits_WebResource];
GO
IF OBJECT_ID(N'[dbo].[FK_Brand_inherits_WebPage]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[WebResourceSet_Brand] DROP CONSTRAINT [FK_Brand_inherits_WebPage];
GO
IF OBJECT_ID(N'[dbo].[FK_Product_inherits_WebPage]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[WebResourceSet_Product] DROP CONSTRAINT [FK_Product_inherits_WebPage];
GO
IF OBJECT_ID(N'[dbo].[FK_Category_inherits_WebPage]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[WebResourceSet_Category] DROP CONSTRAINT [FK_Category_inherits_WebPage];
GO
IF OBJECT_ID(N'[dbo].[FK_File_inherits_WebResource]', 'F') IS NOT NULL
    ALTER TABLE [dbo].[WebResourceSet_File] DROP CONSTRAINT [FK_File_inherits_WebResource];
GO

-- --------------------------------------------------
-- Dropping existing tables
-- --------------------------------------------------

IF OBJECT_ID(N'[dbo].[WebResourceSet]', 'U') IS NOT NULL
    DROP TABLE [dbo].[WebResourceSet];
GO
IF OBJECT_ID(N'[dbo].[Descriptions]', 'U') IS NOT NULL
    DROP TABLE [dbo].[Descriptions];
GO
IF OBJECT_ID(N'[dbo].[PropertyGroups]', 'U') IS NOT NULL
    DROP TABLE [dbo].[PropertyGroups];
GO
IF OBJECT_ID(N'[dbo].[Features]', 'U') IS NOT NULL
    DROP TABLE [dbo].[Features];
GO
IF OBJECT_ID(N'[dbo].[FeatureValues]', 'U') IS NOT NULL
    DROP TABLE [dbo].[FeatureValues];
GO
IF OBJECT_ID(N'[dbo].[DescriptionFiles]', 'U') IS NOT NULL
    DROP TABLE [dbo].[DescriptionFiles];
GO
IF OBJECT_ID(N'[dbo].[ProductFiles]', 'U') IS NOT NULL
    DROP TABLE [dbo].[ProductFiles];
GO
IF OBJECT_ID(N'[dbo].[WebResourceSet_WebPage]', 'U') IS NOT NULL
    DROP TABLE [dbo].[WebResourceSet_WebPage];
GO
IF OBJECT_ID(N'[dbo].[WebResourceSet_Brand]', 'U') IS NOT NULL
    DROP TABLE [dbo].[WebResourceSet_Brand];
GO
IF OBJECT_ID(N'[dbo].[WebResourceSet_Product]', 'U') IS NOT NULL
    DROP TABLE [dbo].[WebResourceSet_Product];
GO
IF OBJECT_ID(N'[dbo].[WebResourceSet_Category]', 'U') IS NOT NULL
    DROP TABLE [dbo].[WebResourceSet_Category];
GO
IF OBJECT_ID(N'[dbo].[WebResourceSet_File]', 'U') IS NOT NULL
    DROP TABLE [dbo].[WebResourceSet_File];
GO

-- --------------------------------------------------
-- Creating all tables
-- --------------------------------------------------

-- Creating table 'WebResourceSet'
CREATE TABLE [dbo].[WebResourceSet] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Url] nvarchar(max)  NOT NULL,
    [Status] tinyint  NOT NULL,
    [Errors] tinyint  NOT NULL,
    [Name] nvarchar(max)  NULL
);
GO

-- Creating table 'Descriptions'
CREATE TABLE [dbo].[Descriptions] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Text] nvarchar(max)  NOT NULL,
    [BrandDescription_Description_Id] int  NOT NULL,
    [ProductDescription_Description_Id] int  NOT NULL,
    [CategoryDescription_Description_Id] int  NOT NULL
);
GO

-- Creating table 'PropertyGroups'
CREATE TABLE [dbo].[PropertyGroups] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Name] nvarchar(max)  NOT NULL
);
GO

-- Creating table 'Features'
CREATE TABLE [dbo].[Features] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Name] nvarchar(max)  NOT NULL,
    [IsMultiple] bit  NOT NULL,
    [Group_Id] int  NULL
);
GO

-- Creating table 'FeatureValues'
CREATE TABLE [dbo].[FeatureValues] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Data] nvarchar(max)  NOT NULL,
    [ProductId] int  NOT NULL,
    [Feature_Id] int  NOT NULL
);
GO

-- Creating table 'DescriptionFiles'
CREATE TABLE [dbo].[DescriptionFiles] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [DescriptionId] int  NOT NULL,
    [FileId] int  NOT NULL
);
GO

-- Creating table 'ProductFiles'
CREATE TABLE [dbo].[ProductFiles] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [IsImage] nvarchar(max)  NOT NULL,
    [ProductId] int  NOT NULL,
    [FileId] int  NOT NULL
);
GO

-- Creating table 'WebResourceSet_WebPage'
CREATE TABLE [dbo].[WebResourceSet_WebPage] (
    [Title] nvarchar(max)  NULL,
    [MetaKeywords] nvarchar(max)  NULL,
    [MetaDescription] nvarchar(max)  NULL,
    [Id] int  NOT NULL
);
GO

-- Creating table 'WebResourceSet_Brand'
CREATE TABLE [dbo].[WebResourceSet_Brand] (
    [FileId] int  NULL,
    [Id] int  NOT NULL
);
GO

-- Creating table 'WebResourceSet_Product'
CREATE TABLE [dbo].[WebResourceSet_Product] (
    [Price] decimal(18,0)  NULL,
    [Sku] nvarchar(max)  NULL,
    [ListPrice] decimal(18,0)  NULL,
    [Quantity] smallint  NULL,
    [Id] int  NOT NULL,
    [Category_Id] int  NOT NULL,
    [Brand_Id] int  NULL
);
GO

-- Creating table 'WebResourceSet_Category'
CREATE TABLE [dbo].[WebResourceSet_Category] (
    [Page] smallint  NOT NULL,
    [Level] smallint  NOT NULL,
    [CategoryId] int  NULL,
    [FileId] int  NULL,
    [Id] int  NOT NULL
);
GO

-- Creating table 'WebResourceSet_File'
CREATE TABLE [dbo].[WebResourceSet_File] (
    [Id] int  NOT NULL
);
GO

-- --------------------------------------------------
-- Creating all PRIMARY KEY constraints
-- --------------------------------------------------

-- Creating primary key on [Id] in table 'WebResourceSet'
ALTER TABLE [dbo].[WebResourceSet]
ADD CONSTRAINT [PK_WebResourceSet]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'Descriptions'
ALTER TABLE [dbo].[Descriptions]
ADD CONSTRAINT [PK_Descriptions]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'PropertyGroups'
ALTER TABLE [dbo].[PropertyGroups]
ADD CONSTRAINT [PK_PropertyGroups]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'Features'
ALTER TABLE [dbo].[Features]
ADD CONSTRAINT [PK_Features]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'FeatureValues'
ALTER TABLE [dbo].[FeatureValues]
ADD CONSTRAINT [PK_FeatureValues]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'DescriptionFiles'
ALTER TABLE [dbo].[DescriptionFiles]
ADD CONSTRAINT [PK_DescriptionFiles]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'ProductFiles'
ALTER TABLE [dbo].[ProductFiles]
ADD CONSTRAINT [PK_ProductFiles]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'WebResourceSet_WebPage'
ALTER TABLE [dbo].[WebResourceSet_WebPage]
ADD CONSTRAINT [PK_WebResourceSet_WebPage]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'WebResourceSet_Brand'
ALTER TABLE [dbo].[WebResourceSet_Brand]
ADD CONSTRAINT [PK_WebResourceSet_Brand]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'WebResourceSet_Product'
ALTER TABLE [dbo].[WebResourceSet_Product]
ADD CONSTRAINT [PK_WebResourceSet_Product]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'WebResourceSet_Category'
ALTER TABLE [dbo].[WebResourceSet_Category]
ADD CONSTRAINT [PK_WebResourceSet_Category]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- Creating primary key on [Id] in table 'WebResourceSet_File'
ALTER TABLE [dbo].[WebResourceSet_File]
ADD CONSTRAINT [PK_WebResourceSet_File]
    PRIMARY KEY CLUSTERED ([Id] ASC);
GO

-- --------------------------------------------------
-- Creating all FOREIGN KEY constraints
-- --------------------------------------------------

-- Creating foreign key on [BrandDescription_Description_Id] in table 'Descriptions'
ALTER TABLE [dbo].[Descriptions]
ADD CONSTRAINT [FK_BrandDescription]
    FOREIGN KEY ([BrandDescription_Description_Id])
    REFERENCES [dbo].[WebResourceSet_Brand]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_BrandDescription'
CREATE INDEX [IX_FK_BrandDescription]
ON [dbo].[Descriptions]
    ([BrandDescription_Description_Id]);
GO

-- Creating foreign key on [ProductDescription_Description_Id] in table 'Descriptions'
ALTER TABLE [dbo].[Descriptions]
ADD CONSTRAINT [FK_ProductDescription]
    FOREIGN KEY ([ProductDescription_Description_Id])
    REFERENCES [dbo].[WebResourceSet_Product]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_ProductDescription'
CREATE INDEX [IX_FK_ProductDescription]
ON [dbo].[Descriptions]
    ([ProductDescription_Description_Id]);
GO

-- Creating foreign key on [CategoryDescription_Description_Id] in table 'Descriptions'
ALTER TABLE [dbo].[Descriptions]
ADD CONSTRAINT [FK_CategoryDescription]
    FOREIGN KEY ([CategoryDescription_Description_Id])
    REFERENCES [dbo].[WebResourceSet_Category]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_CategoryDescription'
CREATE INDEX [IX_FK_CategoryDescription]
ON [dbo].[Descriptions]
    ([CategoryDescription_Description_Id]);
GO

-- Creating foreign key on [Category_Id] in table 'WebResourceSet_Product'
ALTER TABLE [dbo].[WebResourceSet_Product]
ADD CONSTRAINT [FK_ProductCategory]
    FOREIGN KEY ([Category_Id])
    REFERENCES [dbo].[WebResourceSet_Category]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_ProductCategory'
CREATE INDEX [IX_FK_ProductCategory]
ON [dbo].[WebResourceSet_Product]
    ([Category_Id]);
GO

-- Creating foreign key on [Brand_Id] in table 'WebResourceSet_Product'
ALTER TABLE [dbo].[WebResourceSet_Product]
ADD CONSTRAINT [FK_ProductBrand]
    FOREIGN KEY ([Brand_Id])
    REFERENCES [dbo].[WebResourceSet_Brand]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_ProductBrand'
CREATE INDEX [IX_FK_ProductBrand]
ON [dbo].[WebResourceSet_Product]
    ([Brand_Id]);
GO

-- Creating foreign key on [CategoryId] in table 'WebResourceSet_Category'
ALTER TABLE [dbo].[WebResourceSet_Category]
ADD CONSTRAINT [FK_CategoryCategory]
    FOREIGN KEY ([CategoryId])
    REFERENCES [dbo].[WebResourceSet_Category]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_CategoryCategory'
CREATE INDEX [IX_FK_CategoryCategory]
ON [dbo].[WebResourceSet_Category]
    ([CategoryId]);
GO

-- Creating foreign key on [Group_Id] in table 'Features'
ALTER TABLE [dbo].[Features]
ADD CONSTRAINT [FK_FeatureFeatureGroup]
    FOREIGN KEY ([Group_Id])
    REFERENCES [dbo].[PropertyGroups]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_FeatureFeatureGroup'
CREATE INDEX [IX_FK_FeatureFeatureGroup]
ON [dbo].[Features]
    ([Group_Id]);
GO

-- Creating foreign key on [Feature_Id] in table 'FeatureValues'
ALTER TABLE [dbo].[FeatureValues]
ADD CONSTRAINT [FK_FeatureValueFeature]
    FOREIGN KEY ([Feature_Id])
    REFERENCES [dbo].[Features]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_FeatureValueFeature'
CREATE INDEX [IX_FK_FeatureValueFeature]
ON [dbo].[FeatureValues]
    ([Feature_Id]);
GO

-- Creating foreign key on [ProductId] in table 'FeatureValues'
ALTER TABLE [dbo].[FeatureValues]
ADD CONSTRAINT [FK_FeatureValueProduct]
    FOREIGN KEY ([ProductId])
    REFERENCES [dbo].[WebResourceSet_Product]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_FeatureValueProduct'
CREATE INDEX [IX_FK_FeatureValueProduct]
ON [dbo].[FeatureValues]
    ([ProductId]);
GO

-- Creating foreign key on [DescriptionId] in table 'DescriptionFiles'
ALTER TABLE [dbo].[DescriptionFiles]
ADD CONSTRAINT [FK_DescriptionFileDescription]
    FOREIGN KEY ([DescriptionId])
    REFERENCES [dbo].[Descriptions]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_DescriptionFileDescription'
CREATE INDEX [IX_FK_DescriptionFileDescription]
ON [dbo].[DescriptionFiles]
    ([DescriptionId]);
GO

-- Creating foreign key on [FileId] in table 'DescriptionFiles'
ALTER TABLE [dbo].[DescriptionFiles]
ADD CONSTRAINT [FK_DescriptionFileFile]
    FOREIGN KEY ([FileId])
    REFERENCES [dbo].[WebResourceSet_File]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_DescriptionFileFile'
CREATE INDEX [IX_FK_DescriptionFileFile]
ON [dbo].[DescriptionFiles]
    ([FileId]);
GO

-- Creating foreign key on [FileId] in table 'WebResourceSet_Brand'
ALTER TABLE [dbo].[WebResourceSet_Brand]
ADD CONSTRAINT [FK_BrandFile]
    FOREIGN KEY ([FileId])
    REFERENCES [dbo].[WebResourceSet_File]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_BrandFile'
CREATE INDEX [IX_FK_BrandFile]
ON [dbo].[WebResourceSet_Brand]
    ([FileId]);
GO

-- Creating foreign key on [FileId] in table 'WebResourceSet_Category'
ALTER TABLE [dbo].[WebResourceSet_Category]
ADD CONSTRAINT [FK_CategoryFile]
    FOREIGN KEY ([FileId])
    REFERENCES [dbo].[WebResourceSet_File]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_CategoryFile'
CREATE INDEX [IX_FK_CategoryFile]
ON [dbo].[WebResourceSet_Category]
    ([FileId]);
GO

-- Creating foreign key on [ProductId] in table 'ProductFiles'
ALTER TABLE [dbo].[ProductFiles]
ADD CONSTRAINT [FK_ProductFileProduct]
    FOREIGN KEY ([ProductId])
    REFERENCES [dbo].[WebResourceSet_Product]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_ProductFileProduct'
CREATE INDEX [IX_FK_ProductFileProduct]
ON [dbo].[ProductFiles]
    ([ProductId]);
GO

-- Creating foreign key on [FileId] in table 'ProductFiles'
ALTER TABLE [dbo].[ProductFiles]
ADD CONSTRAINT [FK_ProductFileFile]
    FOREIGN KEY ([FileId])
    REFERENCES [dbo].[WebResourceSet_File]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Creating non-clustered index for FOREIGN KEY 'FK_ProductFileFile'
CREATE INDEX [IX_FK_ProductFileFile]
ON [dbo].[ProductFiles]
    ([FileId]);
GO

-- Creating foreign key on [Id] in table 'WebResourceSet_WebPage'
ALTER TABLE [dbo].[WebResourceSet_WebPage]
ADD CONSTRAINT [FK_WebPage_inherits_WebResource]
    FOREIGN KEY ([Id])
    REFERENCES [dbo].[WebResourceSet]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Creating foreign key on [Id] in table 'WebResourceSet_Brand'
ALTER TABLE [dbo].[WebResourceSet_Brand]
ADD CONSTRAINT [FK_Brand_inherits_WebPage]
    FOREIGN KEY ([Id])
    REFERENCES [dbo].[WebResourceSet_WebPage]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Creating foreign key on [Id] in table 'WebResourceSet_Product'
ALTER TABLE [dbo].[WebResourceSet_Product]
ADD CONSTRAINT [FK_Product_inherits_WebPage]
    FOREIGN KEY ([Id])
    REFERENCES [dbo].[WebResourceSet_WebPage]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Creating foreign key on [Id] in table 'WebResourceSet_Category'
ALTER TABLE [dbo].[WebResourceSet_Category]
ADD CONSTRAINT [FK_Category_inherits_WebPage]
    FOREIGN KEY ([Id])
    REFERENCES [dbo].[WebResourceSet_WebPage]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Creating foreign key on [Id] in table 'WebResourceSet_File'
ALTER TABLE [dbo].[WebResourceSet_File]
ADD CONSTRAINT [FK_File_inherits_WebResource]
    FOREIGN KEY ([Id])
    REFERENCES [dbo].[WebResourceSet]
        ([Id])
    ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- --------------------------------------------------
-- Script has ended
-- --------------------------------------------------