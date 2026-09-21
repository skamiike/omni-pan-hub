import { notFound } from 'next/navigation';

export default async function CreatorProfile({ params }: { params: { creator: string } }) {
  const { creator } = await params;
  
  // Dummy data for demo - in production this comes from a database based on 'creator'
  const creatorData = {
    name: creator,
    genre: "Cyberpunk 3D Modeler",
    bio: "Creating futuristic 3D assets and VTuber models.",
    themeColor: "#0f172a", // Custom theme color for this creator
    accentColor: "#3b82f6",
    price: "100 MATIC",
    works: [
      { id: 1, title: "Neon City Concept", image: "https://placehold.co/400x300/1e293b/fff?text=Art+1" },
      { id: 2, title: "Cyber Samurai", image: "https://placehold.co/400x300/1e293b/fff?text=Art+2" },
      { id: 3, title: "Holographic Pet", image: "https://placehold.co/400x300/1e293b/fff?text=Art+3" }
    ]
  };

  return (
    <div className="min-h-screen text-white" style={{ backgroundColor: creatorData.themeColor }}>
      {/* Creator Banner & Profile */}
      <div className="w-full h-64 bg-gradient-to-r from-gray-900 to-black relative">
        <div className="absolute -bottom-16 left-1/2 transform -translate-x-1/2">
          <div className="w-32 h-32 rounded-full border-4 border-white bg-gray-800 flex items-center justify-center text-4xl font-bold shadow-xl">
            {creatorData.name.charAt(0).toUpperCase()}
          </div>
        </div>
      </div>
      
      <main className="max-w-4xl mx-auto px-4 pt-24 pb-12 text-center">
        <h1 className="text-4xl font-bold mb-2">{creatorData.name}</h1>
        <p className="text-xl text-gray-300 mb-4">{creatorData.genre}</p>
        <p className="max-w-2xl mx-auto text-gray-400 mb-8">{creatorData.bio}</p>
        
        {/* Commission Action */}
        <div className="bg-white/10 backdrop-blur-md rounded-2xl p-8 mb-12 border border-white/20">
          <h2 className="text-2xl font-bold mb-4">Request a Commission</h2>
          <p className="mb-6">Base Price: <span className="font-bold text-xl">{creatorData.price}</span></p>
          <button 
            style={{ backgroundColor: creatorData.accentColor }}
            className="px-8 py-3 rounded-full font-bold text-lg hover:opacity-90 transition-opacity w-full md:w-auto"
          >
            Connect Wallet to Commission
          </button>
          <p className="text-sm text-gray-400 mt-4">Smart Contract Escrow (5% Platform Fee)</p>
        </div>

        {/* Portfolio Grid */}
        <h3 className="text-2xl font-bold mb-6 text-left border-b border-gray-700 pb-2">Portfolio</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {creatorData.works.map(work => (
            <div key={work.id} className="rounded-xl overflow-hidden shadow-lg bg-gray-800 transition-transform hover:scale-105">
              <img src={work.image} alt={work.title} className="w-full h-48 object-cover" />
              <div className="p-4">
                <h4 className="font-bold">{work.title}</h4>
              </div>
            </div>
          ))}
        </div>
      </main>
    </div>
  );
}
