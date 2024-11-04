const mysql = require('mysql2');

const db = mysql.createConnection({
   host: 'terraform-20241104123538121200000003.c5g22ewq4ztf.us-east-1.rds.amazonaws.com',
   port: '3306',
   user: 'admin',
   password: 'admin123',
   database: 'MySQLdatabase'
});

module.exports = db;