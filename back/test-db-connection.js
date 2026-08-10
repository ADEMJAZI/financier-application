require('dotenv').config();
const mongoose = require('mongoose');

async function testConnection() {
  const uri = process.env.MONGODB_URI;
  
  console.log('🔍 Test de connexion MongoDB Atlas...\n');
  console.log('📝 URI:', uri.replace(/:[^:@]+@/, ':****@')); // Hide password
  
  try {
    console.log('\n⏳ Connexion en cours...');
    
    await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 15000,
      socketTimeoutMS: 45000,
    });
    
    console.log('\n✅ ✅ ✅ SUCCÈS! ✅ ✅ ✅');
    console.log('✅ Connexion à MongoDB Atlas réussie!');
    console.log(`📊 Base de données: ${mongoose.connection.name}`);
    console.log(`🏷️  Host: ${mongoose.connection.host}`);
    
    await mongoose.disconnect();
    console.log('\n👍 Test terminé avec succès!\n');
    process.exit(0);
    
  } catch (error) {
    console.error('\n❌ ❌ ❌ ÉCHEC! ❌ ❌ ❌');
    console.error('❌ Erreur de connexion:', error.message);
    
    if (error.message.includes('bad auth')) {
      console.error('\n💡 SOLUTION:');
      console.error('   Le nom d\'utilisateur ou mot de passe est incorrect.');
      console.error('\n📋 Étapes à suivre:');
      console.error('   1. Allez sur https://cloud.mongodb.com/');
      console.error('   2. Sélectionnez votre projet');
      console.error('   3. Allez dans "Database Access"');
      console.error('   4. Vérifiez que l\'utilisateur "espritprojt" existe');
      console.error('   5. Réinitialisez le mot de passe si nécessaire');
      console.error('   6. Mettez à jour le mot de passe dans .env');
      console.error('\n⚠️  Si le mot de passe contient des caractères spéciaux (@, #, !, etc.),');
      console.error('    ils doivent être encodés en URL.');
    } else if (error.message.includes('ENOTFOUND')) {
      console.error('\n💡 SOLUTION:');
      console.error('   Impossible de trouver le serveur MongoDB.');
      console.error('   Vérifiez votre connexion internet et l\'URL du cluster.');
    } else if (error.message.includes('ETIMEDOUT')) {
      console.error('\n💡 SOLUTION:');
      console.error('   1. Vérifiez votre connexion internet');
      console.error('   2. Vérifiez que votre IP est autorisée dans MongoDB Atlas');
      console.error('      (Network Access -> Add IP Address)');
    }
    
    console.error('\n');
    process.exit(1);
  }
}

testConnection();
