import Link from 'next/link';

export default function Marketplace() {
  // Dummy data representing items pulled from the blockchain / Supabase
  const items = [
    {
      id: 1,
      title: "Neon City Concept - Original",
      creator: "Cyberpunk 3D Modeler",
      owner: "Collector_0x82",
      type: "auction",
      currentBid: "1,250 MATIC",
      timeLeft: "02h 45m",
      image: "https://placehold.co/400x300/1e293b/fff?text=Neon+City",
    },
    {
      id: 2,
      title: "Holographic Pet - Rare Edition",
      creator: "Cyberpunk 3D Modeler",
      owner: "0x4A...9bF",
      type: "fixed",
      price: "500 MATIC",
      image: "https://placehold.co/400x300/1e293b/fff?text=Holo+Pet",
    },
    {
      id: 3,
      title: "Physical Rolex Daytona (RWA Token)",
      creator: "Luxury Vault",
      owner: "Vault_Deployer",
      type: "auction",
      currentBid: "15,000 USDC",
      timeLeft: "14h 12m",
      image: "https://placehold.co/400x300/1e293b/fff?text=Rolex+RWA",
    }
  ];

  return (
    <div className="min-h-screen bg-black text-white px-6 py-12">
      <div className="max-w-6xl mx-auto">
        
        {/* Header */}
        <div className="flex justify-between items-end mb-12 border-b border-gray-800 pb-6">
          <div>
            <h1 className="text-4xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-green-400 to-blue-500 mb-2">
              Secondary Market & Auctions
            </h1>
            <p className="text-gray-400">Trade, Bid, and Collect Rare NFTs & RWA. 10% Royalties go directly to creators!</p>
          </div>
          <div className="flex gap-4">
            <button className="px-4 py-2 border border-gray-600 rounded-lg hover:bg-gray-800">Filter: All</button>
            <button className="px-4 py-2 bg-blue-600 rounded-lg hover:bg-blue-700 font-bold">Connect Wallet</button>
          </div>
        </div>

        {/* Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {items.map(item => (
            <div key={item.id} className="bg-gray-900 border border-gray-800 rounded-2xl overflow-hidden hover:border-gray-600 transition-colors">
              <img src={item.image} alt={item.title} className="w-full h-56 object-cover" />
              
              <div className="p-6">
                <div className="flex justify-between items-start mb-4">
                  <h2 className="text-xl font-bold">{item.title}</h2>
                  {item.type === 'auction' ? (
                    <span className="bg-red-500/20 text-red-400 text-xs font-bold px-2 py-1 rounded animate-pulse">LIVE AUCTION</span>
                  ) : (
                    <span className="bg-green-500/20 text-green-400 text-xs font-bold px-2 py-1 rounded">FOR SALE</span>
                  )}
                </div>
                
                <p className="text-sm text-gray-400 mb-1">Creator: <span className="text-blue-400">{item.creator}</span></p>
                <p className="text-sm text-gray-400 mb-6">Owner: {item.owner}</p>

                {item.type === 'auction' ? (
                  <div className="bg-black p-4 rounded-xl border border-gray-800 flex justify-between items-center">
                    <div>
                      <p className="text-xs text-gray-500">Current Bid</p>
                      <p className="text-lg font-bold text-red-400">{item.currentBid}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-xs text-gray-500">Ends in</p>
                      <p className="font-mono">{item.timeLeft}</p>
                    </div>
                  </div>
                ) : (
                  <div className="bg-black p-4 rounded-xl border border-gray-800">
                    <p className="text-xs text-gray-500">Fixed Price</p>
                    <p className="text-lg font-bold text-green-400">{item.price}</p>
                  </div>
                )}

                <button className="w-full mt-6 py-3 rounded-xl font-bold bg-white text-black hover:bg-gray-200 transition-colors">
                  {item.type === 'auction' ? 'Place Bid' : 'Buy Now'}
                </button>
              </div>
            </div>
          ))}
        </div>

      </div>
    </div>
  );
}
