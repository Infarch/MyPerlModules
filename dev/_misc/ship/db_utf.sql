CREATE TABLE sourcedata (
    id INTEGER NOT NULL,
    url TEXT,
    content TEXT,
    cdate TEXT DEFAULT (date('now')),
    CONSTRAINT PK_sourcedata PRIMARY KEY (id)
);
CREATE UNIQUE INDEX IDX_sourcedata_1 ON sourcedata (url);


CREATE TABLE shipowner (
    id INTEGER NOT NULL,
    external_id TEXT,
    name_rus TEXT,
    name_eng TEXT,
    adress_rus TEXT,
    adress_eng TEXT,
    phone TEXT,
    fax TEXT,
    email TEXT,
    telex TEXT,
    web TEXT,
    CONSTRAINT PK_shipowner PRIMARY KEY (id)
);
CREATE UNIQUE INDEX IDX_shipowner_1 ON shipowner (external_id);


CREATE TABLE ship (
    id INTEGER NOT NULL,
    rsnum TEXT NOT NULL,
    imonum TEXT,
    callsign TEXT,
    shipowner_id INTEGER,
    CONSTRAINT PK_ship PRIMARY KEY (id),
    FOREIGN KEY (shipowner_id) REFERENCES shipowner (id)
);
CREATE UNIQUE INDEX IDX_ship_1 ON ship (rsnum);


CREATE TABLE category (
    id INTEGER NOT NULL,
    name_rus TEXT NOT NULL,
    name_eng TEXT NOT NULL,
    order_number INTEGER NOT NULL,
    CONSTRAINT PK_category PRIMARY KEY (id)
);


CREATE TABLE property (
    id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    name_rus TEXT NOT NULL,
    name_eng TEXT NOT NULL,
    order_number INTEGER NOT NULL,
    CONSTRAINT PK_property PRIMARY KEY (id),
    FOREIGN KEY (category_id) REFERENCES category (id)
);

CREATE TABLE value (
    id INTEGER NOT NULL,
    property_id INTEGER NOT NULL,
    ship_id INTEGER NOT NULL,
    value_rus TEXT,
    value_eng TEXT,
    CONSTRAINT PK_value PRIMARY KEY (id),
    FOREIGN KEY (property_id) REFERENCES property (id),
    FOREIGN KEY (ship_id) REFERENCES ship (id)
);

insert into category(id,name_rus,name_eng,order_number)values(1,'ОБЩИЕ СВЕДЕНИЯ','GENERAL INFORMATION', 1);
insert into property(id,category_id,name_rus,name_eng,order_number)values(1,1,'Название','Name', 1);
insert into property(id,category_id,name_rus,name_eng,order_number)values(2,1,'Бывшее название','Former name', 2);
insert into property(id,category_id,name_rus,name_eng,order_number)values(3,1,'Год смены названия','Year name change', 3);
insert into property(id,category_id,name_rus,name_eng,order_number)values(4,1,'Регистровый номер','RS number', 4);
insert into property(id,category_id,name_rus,name_eng,order_number)values(5,1,'ИМО','IMO number', 5);
insert into property(id,category_id,name_rus,name_eng,order_number)values(6,1,'Позывной сигнал','Call sign', 6);
insert into property(id,category_id,name_rus,name_eng,order_number)values(7,1,'Порт приписки','Port of registry', 7);
insert into property(id,category_id,name_rus,name_eng,order_number)values(8,1,'Флаг','Flag', 8);
insert into property(id,category_id,name_rus,name_eng,order_number)values(9,1,'Очередное освидетельствование (последнее)','Special survey', 9);
insert into property(id,category_id,name_rus,name_eng,order_number)values(10,1,'Символ класса','Class notation', 10);
insert into property(id,category_id,name_rus,name_eng,order_number)values(11,1,'Символ класса(второй; размерения смотри в квадратных скобках)','Class notation (2nd)', 11);
insert into property(id,category_id,name_rus,name_eng,order_number)values(12,1,'Уровень реновации','Hull renovation', 12);
insert into property(id,category_id,name_rus,name_eng,order_number)values(13,1,'Дата реновации','Date of renovation', 13);
insert into category(id,name_rus,name_eng,order_number)values(2,'ТИП СУДНА','SHIP TYPE', 2);
insert into property(id,category_id,name_rus,name_eng,order_number)values(14,2,'Тип судна','Basic type', 1);
insert into property(id,category_id,name_rus,name_eng,order_number)values(15,2,'Подтипы','Subtypes', 2);
insert into category(id,name_rus,name_eng,order_number)values(3,'СВЕДЕНИЯ О ПОСТРОЙКЕ','CONSTRUCTION DETAILS', 3);
insert into property(id,category_id,name_rus,name_eng,order_number)values(16,3,' Дата постройки','Date of build', 1);
insert into property(id,category_id,name_rus,name_eng,order_number)values(17,3,'Место постройки','Country of build', 2);
insert into property(id,category_id,name_rus,name_eng,order_number)values(18,3,'Строительный номер','Hull No', 3);
insert into category(id,name_rus,name_eng,order_number)values(4,'РАЗМЕРЫ И СКОРОСТЬ','DIMENSIONS AND SPEED', 4);
insert into property(id,category_id,name_rus,name_eng,order_number)values(19,4,'Валовая','Gross tonnage', 1);
insert into property(id,category_id,name_rus,name_eng,order_number)values(20,4,'Чистая','Net', 2);
insert into property(id,category_id,name_rus,name_eng,order_number)values(21,4,'Валовая ТМ','Gross TM', 3);
insert into property(id,category_id,name_rus,name_eng,order_number)values(22,4,'Чистая ТМ','Net TM', 4);
insert into property(id,category_id,name_rus,name_eng,order_number)values(23,4,'Дедвейт (т)','Deadweight (tonn)', 5);
insert into property(id,category_id,name_rus,name_eng,order_number)values(24,4,'Водоизмещение (т)','Displacement (tonn)', 6);
insert into property(id,category_id,name_rus,name_eng,order_number)values(25,4,'Длина габаритная (м)','Length OA (m)', 7);
insert into property(id,category_id,name_rus,name_eng,order_number)values(26,4,'Длина расчетная (м)','Length BR (m)', 8);
insert into property(id,category_id,name_rus,name_eng,order_number)values(27,4,'Ширина габаритная (м)','Breadth extreme (m)', 9);
insert into property(id,category_id,name_rus,name_eng,order_number)values(28,4,'Ширина расчетная (м)','Moulded breadth (m)', 10);
insert into property(id,category_id,name_rus,name_eng,order_number)values(29,4,'Высота борта (м)','Depth (m)', 11);
insert into property(id,category_id,name_rus,name_eng,order_number)values(30,4,'Осадка (м)','Draught (m)', 12);
insert into property(id,category_id,name_rus,name_eng,order_number)values(31,4,'Скорость','Spee', 13);
insert into category(id,name_rus,name_eng,order_number)values(5,'MACHINERY | МЕХАНИЗМЫ','MACHINERY', 5);
insert into property(id,category_id,name_rus,name_eng,order_number)values(32,5,'Год постройки главного двигателя 1','Main engine date of build 1', 1);
insert into property(id,category_id,name_rus,name_eng,order_number)values(33,5,'Место постройки главного двигателя 1','Main engine country of build 1', 2);
insert into property(id,category_id,name_rus,name_eng,order_number)values(34,5,'Количество и мощность главного двигателя 1','Main engine number, power 1', 3);
insert into property(id,category_id,name_rus,name_eng,order_number)values(35,5,'Марка главного двигателя 1','Main engine model No 1', 4);
insert into property(id,category_id,name_rus,name_eng,order_number)values(36,5,'Год постройки главного двигателя 2','Main engine date of build 2', 5);
insert into property(id,category_id,name_rus,name_eng,order_number)values(37,5,'Место постройки главного двигателя 2','Main engine country of build 2', 6);
insert into property(id,category_id,name_rus,name_eng,order_number)values(38,5,'Количество и мощность главного двигателя 2','Main engine number, power 2', 7);
insert into property(id,category_id,name_rus,name_eng,order_number)values(39,5,'Марка главного двигателя 2','Main engine model No 2', 8);
insert into property(id,category_id,name_rus,name_eng,order_number)values(40,5,'Год постройки главного двигателя 3','Main engine date of build 3', 9);
insert into property(id,category_id,name_rus,name_eng,order_number)values(41,5,'Место постройки главного двигателя 3','Main engine country of build 3', 10);
insert into property(id,category_id,name_rus,name_eng,order_number)values(42,5,'Количество и мощность главного двигателя 3','Main engine number, power 3', 11);
insert into property(id,category_id,name_rus,name_eng,order_number)values(43,5,'Марка главного двигателя 3','Main engine model No 3', 12);
insert into property(id,category_id,name_rus,name_eng,order_number)values(44,5,'Год постройки главного двигателя 4','Main engine date of build 4 ', 13);
insert into property(id,category_id,name_rus,name_eng,order_number)values(45,5,'Место постройки главного двигателя 4','Main engine country of build 4', 14);
insert into property(id,category_id,name_rus,name_eng,order_number)values(46,5,'Количество и мощность главного двигателя 4','Main engine number, power 4', 15);
insert into property(id,category_id,name_rus,name_eng,order_number)values(47,5,'Марка главного двигателя 4','Main engine model No 4', 16);
insert into property(id,category_id,name_rus,name_eng,order_number)values(48,5,'Количество и мощность гребных электродвигателей (кВт каждого)','Propulsion E1.motors number,power', 17);
insert into property(id,category_id,name_rus,name_eng,order_number)values(49,5,'Количество и тип движителя','Propeller number, type', 18);
insert into property(id,category_id,name_rus,name_eng,order_number)values(50,5,'Количество лопастей','Blades', 19);
insert into property(id,category_id,name_rus,name_eng,order_number)values(51,5,'Количество и мощность ганераторов (кВт каждого)','Generators number, power', 20);
insert into property(id,category_id,name_rus,name_eng,order_number)values(52,5,'Количество котлов','Main boiler number', 21);
insert into property(id,category_id,name_rus,name_eng,order_number)values(53,5,'Тип котла','Main boiler type', 22);
insert into property(id,category_id,name_rus,name_eng,order_number)values(54,5,'Давление (МПа)','Pressure (MPa)', 23);
insert into property(id,category_id,name_rus,name_eng,order_number)values(55,5,'Поверхность нагрева (кв.м.)','Heating surface (sq.m.)', 24);
insert into category(id,name_rus,name_eng,order_number)values(6,'ХОЛОДИЛЬНАЯ УСТАНОВКА И РАДИО','REF. CLASS AND NAVIGATION AIDS', 6);
insert into property(id,category_id,name_rus,name_eng,order_number)values(56,6,'Холодильная установка','Ref. class', 1);
insert into property(id,category_id,name_rus,name_eng,order_number)values(57,6,'Температура охлаждения трюмов','Ref. temperature', 2);
insert into property(id,category_id,name_rus,name_eng,order_number)values(58,6,'Хладагенты','Refrigerant', 3);
insert into property(id,category_id,name_rus,name_eng,order_number)values(59,6,'Радио и навигационное оборудование','Aids of navigation', 4);
insert into property(id,category_id,name_rus,name_eng,order_number)values(60,6,'Морской район ГМССБ','GMDSS sea area', 5);
insert into category(id,name_rus,name_eng,order_number)values(7,'ЗАПАСЫ И СНАБЖЕНИЕ','CAPACITIES', 7);
insert into property(id,category_id,name_rus,name_eng,order_number)values(61,7,'Запасы топлива (т)','Fuel oil bunkers (tons)', 1);
insert into property(id,category_id,name_rus,name_eng,order_number)values(62,7,'Типы топлива','Fuel oil type', 2);
insert into property(id,category_id,name_rus,name_eng,order_number)values(63,7,'Водяной балласт (т)','Water ballast (tons)', 3);
insert into property(id,category_id,name_rus,name_eng,order_number)values(64,7,'Подогреватели','Heating coils', 4);
insert into property(id,category_id,name_rus,name_eng,order_number)values(65,7,'Характеристика снабжения','Equipment letter', 5);
insert into property(id,category_id,name_rus,name_eng,order_number)values(66,7,'Категория якорных цепей','Grade of anchor chains', 6);
insert into property(id,category_id,name_rus,name_eng,order_number)values(67,7,'Калибр якорных цепей (мм)','Diameter of anchor chains (mm)', 7);
insert into category(id,name_rus,name_eng,order_number)values(8,'ТРЮМА, ПАЛУБЫ, ПАССАЖИРЫ','HOLDS, DECKS, PASSENGERS', 8);
insert into property(id,category_id,name_rus,name_eng,order_number)values(68,8,'Количество и кубатура сухогрузных трюмов (куб.метров каждого)','Dry cargo holds,number*cubic capacity each(cub.m)', 1);
insert into property(id,category_id,name_rus,name_eng,order_number)values(69,8,'Охлаждаемые грузовые помещения (общее количество*суммарная кубатура)','Refrigerated cargo spaces (total number-total cubic capacity(cub.m))', 2);
insert into property(id,category_id,name_rus,name_eng,order_number)values(70,8,'Танки наливные (общее количество*суммарная кубатура)','Tanks (total number-total cubic capacity(cub.m))', 3);
insert into property(id,category_id,name_rus,name_eng,order_number)values(71,8,'Количество контейнеров (TEU)','Containers (number TEU)', 4);
insert into property(id,category_id,name_rus,name_eng,order_number)values(72,8,'Количество палуб','Decks', 5);
insert into property(id,category_id,name_rus,name_eng,order_number)values(73,8,'Количество переборок','Bulkheads', 6);
insert into property(id,category_id,name_rus,name_eng,order_number)values(74,8,'Пассажиры коечные','Passengers berthed', 7);
insert into property(id,category_id,name_rus,name_eng,order_number)values(75,8,'Пассажиры бескоечные ','Passengers unberthed', 8);
insert into property(id,category_id,name_rus,name_eng,order_number)values(76,8,'Спецперсонал','Special personnel', 9);
insert into category(id,name_rus,name_eng,order_number)values(9,'ЛЮКИ, СТРЕЛЫ, КРАНЫ','HATCHES, DERRICKS, CRANES', 9);
insert into property(id,category_id,name_rus,name_eng,order_number)values(77,9,'Грузовые люки (количество - размеры каждого;м)','Hatches (number-size;m)', 1);
insert into property(id,category_id,name_rus,name_eng,order_number)values(78,9,'Стрелы','Derricks (number-lifting capacity;tons)', 2);
insert into property(id,category_id,name_rus,name_eng,order_number)values(79,9,'Краны','Cranes (number-lifting capacity;tons)', 3);
insert into category(id,name_rus,name_eng,order_number)values(10,'СОБСТВЕННИК','REGISTERED OWNER', 10);
insert into property(id,category_id,name_rus,name_eng,order_number)values(80,10,'Registered owner','Registered owner', 1);



