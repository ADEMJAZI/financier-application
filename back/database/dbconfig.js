const mongoose = require('mongoose');

async function connectDB() {
  const envUri = process.env.MONGODB_URI;
  
  if (!envUri) {
    console.error('❌ ERREUR: MONGODB_URI n\'est pas défini dans .env');
    process.exit(1);
  }

  try {
    console.log('🔄 Connexion à MongoDB Atlas en cours...');
    
    await mongoose.connect(envUri, {
      serverSelectionTimeoutMS: 15000,
      socketTimeoutMS: 45000,
    });
    
    console.log('✅ Connexion à MongoDB Atlas établie avec succès!');
    console.log(`📊 Base de données: ${mongoose.connection.name}`);
    
    // Handle connection events
    mongoose.connection.on('error', (err) => {
      console.error('❌ Erreur de connexion MongoDB:', err.message);
    });
    
    mongoose.connection.on('disconnected', () => {
      console.warn('⚠️  MongoDB déconnecté');
    });
    
    mongoose.connection.on('reconnected', () => {
      console.log('✅ MongoDB reconnecté');
    });
    
  } catch (err) {
    console.error('❌ Échec de connexion à MongoDB Atlas');
    console.error('Détails:', err.message);
    
    // Provide helpful error messages
    if (err.message.includes('bad auth')) {
      console.error('\n💡 Solution: Vérifiez vos identifiants MongoDB Atlas:');
      console.error('   1. Nom d\'utilisateur et mot de passe corrects');
      console.error('   2. L\'utilisateur a les permissions sur la base de données');
      console.error('   3. Le mot de passe est correctement encodé dans l\'URL');
    } else if (err.message.includes('ENOTFOUND')) {
      console.error('\n💡 Solution: Vérifiez votre connexion internet et l\'URL du cluster');
    }
    
    process.exit(1);
  }
}

connectDB();

module.exports = mongoose;