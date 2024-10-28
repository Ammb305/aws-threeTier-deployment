const mysql = require('mysql2');

const db = mysql.createConnection({
   host: 'terraform-20241027185710975700000001.c5g22ewq4ztf.us-east-1.rds.amazonaws.com',
   port: '3306',
   user: 'admin',
   password: 'admin123',
   database: 'react_node_app'
});

module.exports = db;